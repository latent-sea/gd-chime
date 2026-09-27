extends RefCounted

## A phrase: words not said yet - an English key, or a pattern and the data
## that fills it, a count, the name of a key, a number written the
## language's way - carried as it is, and said in the language on only as a
## text draws it (text.gd), and again whenever the language changes.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## ENGLISH WORDS ARE PHRASES; DATA IS NOT. A text says a phrase and shows
## anything else - a string above all - as the data it is, however like a
## word it looks: a name stays the name it is, in every language. So every
## word written for a reader is written as a phrase where it is written, and
## the shortest honest way is of(): Phrase.of("Save the day"), the English
## as the key, one call a reader sees is words - the same in a description,
## a recipe, a model and the door, and nothing to remember besides.
##
## A PHRASE SHOWN ON ITS OWN IS IN SENTENCE CASE: "Save", "There is nothing
## to go back to" - its first letter a capital, the rest as English writes
## it. The capital is written in the English where it is written, never
## added as a text draws, so a description reads as what it shows; the
## template's check fails a commit on a phrase starting lowercase unmarked.
## Words said only inside another phrase, filling its pattern mid-sentence,
## are within(), and IT IS WITHIN THAT LOWERS THE FIRST LETTER as the
## phrase is said: "Now %s" filled with within("Recovering") says "Now
## recovering". So a word shown both ways is ONE English and one catalogue
## entry, where a second table of the same words written lowercase used to
## stand beside the first.
##
## THE DOOR'S ANSWER IS A PHRASE, OR NOTHING: a model's would() and told(),
## the door's refusal and dispatch, a control's reason. A refusal with data
## in it - "zoom is not on top" - is with(): its pattern and its name, carried
## together to the text that says it, so the pattern is translated and the
## name put back as it was, and nothing is looked up by what it says. Nothing
## refused is null, and a caller asks `answer == null`.
##
## EVERY ENGLISH PHRASE IS WHERE A TEMPLATE CAN FIND IT: the translators'
## template (words/gd-chime.pot) is written from the code by the words
## template check, which reads the English in a call of this file,
## the register's words where an action is declared, and every string in a
## constant whose name ends in WORDS. English kept as data until a text says
## it - the names of a chart's markers - is such a constant: MARKER_WORDS;
## one said only within another phrase - a filter's comparisons - ends in
## WORDS_WITHIN: COMPARISON_WORDS_WITHIN. A name is the marking because a
## constant may not call a function.
##
## A COUNT OF NONE MAY HAVE WORDS OF ITS OWN - "No matches" rather than "0
## matches" - a key of its own, said whenever the count is 0 before any
## plural is chosen: English's plural rule has no form for zero, so none can
## come from a catalogue's plural, and a language whose rule says 0 as it
## says 1 still says the words for none.
##
## Nothing here says anything: it holds what will be said, and the saying is
## the text's alone. Printed, a phrase is its English - for a log and a test,
## which read what was meant, and never for a reader.

var pattern: String = ""  # the English: a key, or a pattern with %s and %d where the data goes
var data: Array = []  # what fills the pattern: a model's data, or phrases of their own
var many: String = ""  # a count's English for every number but one
var none: String = ""  # a count's English for 0, a key of its own, where it has one
var count: int = 0  # how many a count counts
var naming: bool = false  # a key's or a pad button's name rather than words
var writer: Callable  # a number, money or a date, written the language's way as it is said
var parts: Array = []  # said one after another: a word and the mark beside it
var lowered: bool = false  # said inside another phrase, so its first letter is lowered where it stands


## Words, by their English.
static func of(words: String) -> RefCounted:
	var made: RefCounted = new()
	made.pattern = words
	return made


## A pattern and the data that fills it: "Expecting %s" and the claim.
static func with(words: String, filling: Array) -> RefCounted:
	var made: RefCounted = of(words)
	made.data = filling
	return made


## Words said only inside another phrase, filling its pattern mid-sentence -
## "now %s" filled with "Recovering" - said with their first letter LOWERED,
## since every phrase shown on its own is written in sentence case. The
## English is one key either way, so a word a reader sees in both places -
## a status on its own and the same status in a sentence - is written once
## and translated once. A fragment already written lowercase, a line of a
## sentence broken over several, is lowered to no effect.
static func within(words: String) -> RefCounted:
	var made: RefCounted = of(words)
	made.lowered = true
	return made


## How many, by the English's two forms - "%d item", "%d items" - and, where
## none has words of its own, those: "No items".
static func counted(one: String, other: String, number: int, zero: String = "") -> RefCounted:
	var made: RefCounted = of(one)
	made.many = other
	made.none = zero
	made.count = number
	return made


## The name of a key or a pad button, as the engine or the map writes it.
static func named(name: String) -> RefCounted:
	var made: RefCounted = of(name)
	made.naming = true
	return made


## A number, money or a date: written, the language's way, by this as it is said.
static func written(writing: Callable) -> RefCounted:
	var made: RefCounted = new()
	made.writer = writing
	return made


## Phrases and data said one after another, in the order given: a word and a
## mark beside it, never a sentence, whose order is a language's own.
static func joined(pieces: Array) -> RefCounted:
	var made: RefCounted = new()
	made.parts = pieces
	return made


## The English, as a log or a test reads it: the pattern with its data put
## in, a count by English's rule after its words for none, a writing as it writes.
func _to_string() -> String:
	var words := ""
	if writer.is_valid():
		words = writer.call()
	elif not parts.is_empty():
		# every part in turn, a phrase as its English
		words = "".join(parts.map(func(part: Variant) -> String: return str(part)))
	elif count == 0 and none != "":
		words = none
	elif many != "":
		words = (pattern if count == 1 else many) % count
	else:
		words = pattern if data.is_empty() else pattern % data
	return lower(words) if lowered else words


## Words with their first letter lowered, as a phrase said inside another is.
static func lower(words: String) -> String:
	return words.substr(0, 1).to_lower() + words.substr(1)
