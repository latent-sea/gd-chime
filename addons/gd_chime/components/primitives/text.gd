extends "../../presentation.gd"

const Motion := preload("../../motion.gd")
const Bound := preload("bound.gd")
const Styled := preload("styled.gd")
const Language := preload("../../language.gd")
const Phrase := preload("../../phrase.gd")
const DrawnReach := preload("drawn_reach.gd")
const GradedWords := preload("graded_words.gd")

## Words: a phrase, data, or a bound value read again whenever what it read
## moves - a phrase said in the language on as it is drawn.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The style is a Theme name, a variation of Label, and the words are sized
## and coloured by it - graded, where the kind names a gradient
## (graded_words.gd); nothing here knows a colour or a size. Hidden while
## empty when built so, as a reason under a button is.
##
## A REASON WRAPS. It is a sentence on the face of a thing that may be no
## wider than its own words, so it breaks onto more lines at the width it is
## given rather than widening whatever holds it: held to one line, the
## refusal under a back button made a rail as wide as the sentence and
## pushed the rest of its row past the window's edge.
##
## ONLY A TEXT TRANSLATES, AND ONLY AS IT DRAWS (language.gd). English words
## are phrases (phrase.gd) - a key, a pattern and its data, a count, a key's
## name, a number written the language's way - wherever they were written:
## in a description, by a recipe, by a model, or as the door's answer, which
## a reason shows. Anything else - a string above all - is data, shown as it
## is however like a word it looks. The text says a phrase in the language
## on each time it draws, and saying it reads the language on, a value
## (language.gd), so the text follows it and draws again, in place, as it
## follows any value it read: nothing holds words finished in a language no
## longer on, and nothing is built again. The engine is told never to translate a
## label itself: it would take a reader's data spelled like a key - a crate
## called "won" - for a word.
##
## IT ANSWERS FOR ITS OWN REACH (drawn_reach.gd): how far the box its words
## are set in draws past its edges is the look's, so it is worked out the
## first time a line asks after the look or the kind of words last changed,
## and never for words changing - a line placing a row of words again asks
## and walks nothing.

## The one clock, handed in by the builder; none, and a bound style moving switches.
var motion: Motion = null
var _inking: Motion.Run = null  # its colour on the way from one kind's to another's
var _label := Label.new()
var _content: Variant  # a phrase, a string of data, or a Bound reading either
var _hides_empty: bool
var _style: Variant  # a Theme name, or a Bound reading one
var _reach: Array[float] = []  # how far its box draws past each edge, empty until worked out again
## How many times its reach has been worked out, so that it being kept is
## something a test can read rather than something it argues.
var reach_count: int = 0


func _init(chimes: Chimes, content: Variant, style: Variant, in_region: StringName, hides_empty: bool, wraps: bool = false) -> void:
	super(chimes, [], in_region)
	if wraps:
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content = content
	_style = style
	_hides_empty = hides_empty
	_label.theme_type_variation = Styled.name_of(style)
	# words take no press: whatever holds them does
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the words arrive in the language on; the engine translating them again would take a reader's data for a word
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_label)
	# a control's answer, re-read as that control is drawn
	if content is Bound and content.answerer() != null:
		content.answerer().depends(self)


## The words as they stand.
func get_text() -> String:
	return _label.text


func _get_minimum_size() -> Vector2:
	return _label.get_minimum_size()


## Placed, words that wrap have what they need asked again at the width
## they now have - the label, across the whole of this by its anchors,
## works that out only as it is drawn, so words in a screen not yet shown
## would go on needing what they needed at no width, a letter to a line,
## and a stack of screens counting them would be taller than its window.
func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and _label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		update_minimum_size()
	# another look, or the look dressed in another font: the reach is worked out again when next asked
	if what == NOTIFICATION_THEME_CHANGED:
		_reach = []
	# resized or dressed again, its words may stand elsewhere across it: graded across where they are now
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_THEME_CHANGED:
		GradedWords.dress(_label)


## How far its words' box draws past its edge on this side, as last worked out.
func get_reach(side: int) -> float:
	if _reach.is_empty():
		reach_count += 1
		_reach = DrawnReach.walked(self, DrawnReach.worn(self))
	return _reach[side]


## Hidden while empty, its own draw is what shows it again (presentation.gd).
func shows_itself() -> bool:
	return _hides_empty


func refresh() -> void:
	# the kind of words, worn in place when a bound style moves
	var kind := Styled.name_of(_style)
	if _label.theme_type_variation != kind:
		_wear(kind)
	_label.text = said(_content.read() if _content is Bound else _content)
	GradedWords.dress(_label)
	if _hides_empty:
		visible = _label.text != ""


## What a value says, drawn now in the language on: a phrase said - its key,
## its pattern with the data put in as it is, its count or its words for
## none, its name, its
## writing, its parts in turn - and anything else a model's data, as it is.
## A primitive drawing words on a label of its own says them by this too.
static func said(value: Variant) -> String:
	if value == null:
		return ""
	if not value is Phrase:
		return str(value)
	var phrase: Phrase = value
	var words := ""
	if phrase.writer.is_valid():
		words = phrase.writer.call()
	elif not phrase.parts.is_empty():
		# every part in turn: a phrase said, anything else as it is
		words = "".join(phrase.parts.map(func(part: Variant) -> String: return said(part)))
	elif phrase.naming:
		words = Language.named(phrase.pattern)
	# none's own words before any plural: English's rule has no form for zero for a catalogue to give
	elif phrase.count == 0 and phrase.none != "":
		words = Language.word(phrase.none)
	elif phrase.many != "":
		words = Language.counted(phrase.pattern, phrase.many, phrase.count)
	else:
		words = Language.word(phrase.pattern)
		# the data put in as it is, a phrase among it said in turn
		if not phrase.data.is_empty():
			words = words % phrase.data.map(func(one: Variant) -> Variant: return said(one) if one is Phrase else one)
	# said only inside another phrase, its first letter is lowered in the language on, after it is said
	return Phrase.lower(words) if phrase.lowered else words


## Another kind of words worn in place: its size at once, its colour gone
## to smoothly - unless something else inks these words, as a face does its content.
func _wear(kind: StringName) -> void:
	var inked_by_another: bool = _label.has_theme_color_override(&"font_color") and _inking == null
	var before := _label.get_theme_color(&"font_color")
	_label.theme_type_variation = kind
	GradedWords.dress(_label)
	# another kind of words may be set in another box: worked out again, and the line holding it told
	_reach = []
	DrawnReach.tell_holder(self)
	if inked_by_another or motion == null or not is_visible_in_tree():
		return
	var after := _label.get_theme_color(&"font_color", kind)
	if after == before and _inking == null:
		return
	if _inking == null:
		_inking = motion.run(before, after, Motion.RESTYLE, _inked, true, _settled)
	else:
		motion.retarget(_inking, after)


func _inked(colour: Color) -> void:
	_label.add_theme_color_override(&"font_color", colour)


## Arrived: the colour is the kind's own again, and follows the look - graded, if the kind is.
func _settled() -> void:
	_label.remove_theme_color_override(&"font_color")
	_inking = null
	GradedWords.dress(_label)


## The builder's door for words, and for a reason: the pressable's answer.
static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var content: Variant = ui.current_pressable().reason() if desc.kind == &"reason" else desc.props["content"]
	var made: Control = ui.primitive(&"text").new(ui.chimes, content, desc.props["style"], ui.region(), desc.kind == &"reason" or desc.props["hides_empty"], desc.kind == &"reason" or desc.props.get("wraps", false))
	ui.attach(made, parent, desc.facts)
	return made