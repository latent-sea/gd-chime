extends RefCounted

## How wide a label's words stand, shaped as the label shapes them: the
## widest single word - the narrowest they can be set without a word broken
## across lines - and all of them on one line; how many words they are, the
## most lines they can rightly take; and how tall they stand set at the
## widest word's width, the tallest they can rightly be.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## SHAPED AS THE LABEL SHAPES THEM: its words in its font, at a size, in
## the language on, broken only where the text server says a line may
## break between words - the label's own trimming of the spaces at a line's
## ends with it - and never inside a word. The engine's least for words
## that wrap is one pixel across, a letter to a line; what this measures
## stands in its place (text.gd).
##
## ONE MEASURE IS KEPT, by the words, the font, the size, the language on
## and the label's line spacing, and worked out again only when one of them moves, so a label drawn
## again with the same words asks nothing of the text server. A look
## changed under the same font may draw the words otherwise, so whatever
## holds this lets the measure go as its look changes (forget()).
##
## It holds no node and draws nothing.

var _key: Array = []  # what the kept measure was taken from: the words, the font, the size and the language on
var _widest := 0.0  # the widest single word
var _line := 0.0  # the widest line of them all, broken only where the words say a line ends
var _words := 0  # how many pieces they break into, a word to a line
var _tall := 0.0  # how tall their lines stand set at the widest word's width, the label's line spacing between each two


## The widest single word of the label's words at this size, in pixels.
func widest(label: Label, size: int) -> float:
	_measure(label, size)
	return _widest


## The label's words on one line at this size, in pixels: the widest of the
## lines the words themselves end, which is one where they end none.
func one_line(label: Label, size: int) -> float:
	_measure(label, size)
	return _line


## How many words the label's words are at this size: the most lines they
## can take with no word broken, a word to a line.
func words(label: Label, size: int) -> int:
	_measure(label, size)
	return _words


## How tall the label's words stand at this size set at their widest word's
## width: every line's height, with the label's line spacing between each two.
func tall_at_widest(label: Label, size: int) -> float:
	_measure(label, size)
	return _tall


## The kept measure let go: the next question asks the text server again.
func forget() -> void:
	_key = []


## The label's words measured at this size, unless the measure kept is of
## these words in this font, at this size, in the language on.
func _measure(label: Label, size: int) -> void:
	var font := label.get_theme_font(&"font")
	var key := [label.text, font, size, TranslationServer.get_locale(), label.get_theme_constant(&"line_spacing")]
	if key == _key:
		return
	_key = key
	var paragraph := TextParagraph.new()
	paragraph.add_string(label.text, font, size, label.language)
	# broken only where a line may break between words or must, each line's end spaces trimmed as the label trims them
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | label.autowrap_trim_flags
	# no width: a line ends only where the words end one
	paragraph.width = -1.0
	_line = _widest_line(paragraph)
	# a width no word fits in: every word on a line of its own
	paragraph.width = 1.0
	_widest = _widest_line(paragraph)
	_words = paragraph.get_line_count()
	# set at the widest word's width, as the label would be at its least
	paragraph.width = _widest
	_tall = label.get_theme_constant(&"line_spacing") * maxi(paragraph.get_line_count() - 1, 0)
	# every line, its height added
	for line: int in paragraph.get_line_count():
		_tall += paragraph.get_line_size(line).y


## The widest of the lines the paragraph is broken into now.
static func _widest_line(paragraph: TextParagraph) -> float:
	var widest := 0.0
	# every line, for the widest
	for line: int in paragraph.get_line_count():
		widest = maxf(widest, paragraph.get_line_width(line))
	return widest
