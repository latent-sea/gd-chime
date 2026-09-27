extends "controller.gd"

const Look := preload("look.gd")
const Reads := preload("reads.gd")
const Catalogues := preload("catalogues.gd")

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
## THE WORDS ARE CATALOGUES, files read off disk (catalogues.gd): the floor's
## as this is made, an application's own beside them.
##
## THE LANGUAGE IS THE GAME'S: the engine's locale, which this reads and never
## sets of its own accord - made, entering or leaving. Whoever sets it - the
## game, another app, a player's choice told here - the engine tells every
## node; this hears it and, where the language on moved, rings
## LANGUAGE_CHANGED, a global bell, so every text follows. The language on is
## the one with words nearest the locale: French for fr_FR, English for en_GB.
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
## this stands under in the font it gives that script (look.gd): fonts are
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
var _heard: StringName  # the language on when this last heard the locale move
var _telling: bool = false  # whether a choice told here is setting the engine now, heard once it is set


func _init(chimes: Chimes, under: Node) -> void:
	super(chimes, [], Chimes.GLOBAL)
	register_bell(LANGUAGE_CHANGED)
	_under = under
	TranslationServer.set_meta(MISSING, {})
	# the catalogues beside this script, wherever the addon was installed: nothing here knows where it sits
	Catalogues.read((get_script() as Script).resource_path.get_base_dir().path_join(FLOOR_CATALOGUES))
	_heard = current()


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


## A player's choice of language: the game's locale and pseudolocalization
## set - the one truth - and heard once, both set.
func told(_action: StringName, payload: Dictionary) -> Phrase:
	var language: StringName = payload["value"]
	_telling = true
	TranslationServer.pseudolocalization_enabled = language == PSEUDO
	TranslationServer.set_locale(SOURCE if language == PSEUDO else language)
	_telling = false
	_moved()
	return null


## The engine saying its locale moved, whoever moved it: heard, unless a
## choice told here is half way through setting it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and not _telling:
		_moved()


## The locale heard: where the language on moved, the look dressed for its
## script and the bell rung; where it did not - the engine says so on entering
## the tree as well - nothing.
func _moved() -> void:
	if current() == _heard:
		return
	_heard = current()
	var look := Look.worn_by(_under)
	# nothing wearing a look of its own has no fonts to change
	if look != null:
		Look.dress(look, written_in())
	strike(region, LANGUAGE_CHANGED)


## --- the text's lookups ---

## The language on: the pseudo-locale, else the language with words nearest
## the engine's locale, else the locale as it is - words for it there are none.
static func current() -> StringName:
	if TranslationServer.pseudolocalization_enabled:
		return PSEUDO
	var locale := TranslationServer.get_locale()
	var nearest := StringName(locale)
	var closest := 0
	# English and every language a catalogue is held for, for the one nearest the locale
	for language: String in [String(SOURCE)] + Array(TranslationServer.get_loaded_locales()):
		if TranslationServer.compare_locales(locale, language) > closest:
			closest = TranslationServer.compare_locales(locale, language)
			nearest = StringName(language)
	return nearest


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

## The catalogues the engine holds for the language on - a French one for
## fr_FR as for fr: none for English, whose words are their keys, and none
## for the pseudo-locale, which is English.
static func _catalogues() -> Array[Translation]:
	return TranslationServer.find_translations(TranslationServer.get_locale(), false)


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
