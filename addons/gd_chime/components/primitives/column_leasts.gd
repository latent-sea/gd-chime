extends RefCounted

const Text := preload("text.gd")
const Language := preload("../../language.gd")

## The least each column of a line of cells may be (cells.gd): the widest of
## the words it may ever hold - its SAMPLES - drawn in the font the line wears
## for the kind of words its cells are in, in the language on, and the pad
## either side.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A MEASURE IS KEPT ON THE SAMPLES, under the font, the size and the
## language it was taken in. Every line of one table is handed the same
## samples, so the widest words are drawn once for the whole table, not once
## a row; and a sample is a phrase, said in the language on, so the same
## words are as wide as that language writes them - measured in English,
## never offered to the pseudo-locale's longer words, which would be drawn
## over the next column.
##
## EACH ROW KEEPS ITS OWN LEASTS - a line of cells - until it is told to forget them - its
## look, its parts or the language changed - and a least is then measured
## again the first time the line asks for it. It never follows anything itself: the
## line hears what moved.

var _samples: Dictionary  # column -> the words it may hold, their measures kept beside them
var _words_kind: StringName  # the kind of words the cells are in, measured by
var _kept: Dictionary = {}  # column -> its least as last measured for this line


func _init(samples: Dictionary, words_kind: StringName) -> void:
	_samples = samples
	_words_kind = words_kind


## Every least measured again when next asked.
func forget() -> void:
	_kept.clear()


## The least this column may be on this line, with this pad either side.
func of(column: StringName, line: Control, pad: float) -> float:
	if _kept.has(column):
		return _kept[column]
	var font := line.get_theme_font(&"font", _words_kind)
	var font_size := line.get_theme_font_size(&"font_size", _words_kind)
	var held: Dictionary = _samples[column]
	var key := "%d:%d:%s" % [font.get_rid().get_id(), font_size, Language.current()]
	if not held.has(key):
		var widest := 0.0
		# every word the column may hold, for the widest drawn
		for words: Variant in held["words"]:
			widest = maxf(widest, font.get_string_size(Text.said(words), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		held[key] = widest
	_kept[column] = held[key] + 2.0 * pad
	return _kept[column]
