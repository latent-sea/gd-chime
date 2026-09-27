extends "look_boxes.gd"

const Themes := preload("theme.gd")
const Flex := preload("components/primitives/flex.gd")
const Pressables := preload("theme_pressables.gd")

## What every look is made of: the boxes (look_boxes.gd, which this
## extends), the fonts, and the theme entries a design language is written
## in, so a look says what it believes in a few lines and never repeats the
## engine's spelling.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A LOOK is a Theme (theme.gd) built from a palette and then varied: a
## design language is a palette, a type scale, a spacing scale, its fonts,
## and a box for each thing the primitives draw - a pressable's four states
## and its focus, a surface's panel, the grounds a demo names. This file
## holds the half of the vocabulary that puts those INTO a theme, taking
## that theme first: a system FONT by family, the fonts BY SCRIPT, and the
## entries for a pressable's states, a kind of words, a line layout, a field
## and a ground. A line layout takes the flex layout's own constants,
## re-exported here.
##
## FONTS ARE THE LOOK'S, THE SCRIPT IS THE LANGUAGE'S. A language in another
## script needs another font - Japanese in a font with no Japanese in it is
## a row of empty boxes - so a look says, beside its own fonts, which font
## each script it may be read in is drawn in, by ISO 15924 code (fonts()),
## Latin's among them, or a language changed back into Latin would keep
## another script's font, which is said out loud. The language names only
## the script it is written in (language.gd), and a change of language
## dresses the look on the window for it (dress()): its default font becomes
## the one it gives that script, and every text drawn in the default font
## follows, told by the engine as of any change of look. Whoever puts a look
## on dresses it for the language on. A kind of words the look gives a font
## of its own keeps it.

## The flex layout's constants, for a line's justify and align.
const START := Flex.START
const CENTER := Flex.CENTER
const END := Flex.END
const BETWEEN := Flex.BETWEEN
const AROUND := Flex.AROUND
const EVENLY := Flex.EVENLY
const STRETCH := Flex.STRETCH
## The theme type a look's font for each script is kept under, by the script's code.
const FONTS := &"Scripts"
## The script English is written in.
const LATIN := "Latn"


## The nearest thing above this node that reads a look - a Control, or the
## window - since the cascade is theirs, and a viewport between stops it.
static func wearer(node: Node) -> Node:
	var at := node
	# up the tree to the first Control or window
	while not (at is Control or at is Window):
		at = at.get_parent()
	return at


## The look worn above this node: the nearest Theme set on a Control or the
## window, or nothing where none is set.
static func worn_by(node: Node) -> Theme:
	var at := node
	# up the tree to the first Control or window wearing a Theme of its own
	while at != null:
		if (at is Control or at is Window) and at.theme != null:
			return at.theme
		at = at.get_parent()
	return null


## A system font by family, the first the machine has.
static func font(families: Array[String], weight: int = 400, italic: bool = false) -> SystemFont:
	var found := SystemFont.new()
	found.font_names = PackedStringArray(families)
	found.font_weight = weight
	found.font_italic = italic
	return found


## A look's font for each script its words may be written in, by ISO 15924
## code, put into its Theme.
static func fonts(theme: Theme, by_script: Dictionary) -> void:
	if not by_script.has(LATIN):
		push_error("a look's fonts by script need one for %s, or a language changed back into it keeps another script's font" % LATIN)
	# every script the look gives a font
	for script: String in by_script:
		theme.set_font(script, FONTS, by_script[script])


## A look dressed for a script: its default font the one it gives that
## script, where it gives it one.
static func dress(theme: Theme, script: String) -> void:
	if theme.get_font_list(FONTS).has(script):
		theme.default_font = theme.get_font(script, FONTS)


## A pressable's states and its focus, under this type: a box and an ink
## per state, the focus box over whichever shows. A look that draws no
## selected - a local press's chosen one - has it drawn as its glowing.
static func pressable(theme: Theme, type: StringName, boxes: Dictionary, inks: Dictionary, focus: StyleBox, base: StringName = Themes.PRESSABLE) -> void:
	_vary(theme, type, base)
	# every state the look draws, its box and its ink
	for state: StringName in boxes:
		theme.set_stylebox(state, type, boxes[state])
		theme.set_color(StringName("font_color_" + state), type, inks[state])
	if boxes.has(&"glowing") and not boxes.has(&"selected"):
		theme.set_stylebox(&"selected", type, boxes[&"glowing"])
		theme.set_color(&"font_color_selected", type, inks[&"glowing"])
	theme.set_stylebox(&"focus", type, focus)


## A kind of words: its size, and its font and colour when given.
static func words(theme: Theme, kind: StringName, size: int, family: Font = null, colour: Variant = null) -> void:
	theme.set_type_variation(kind, &"Label")
	theme.set_font_size(&"font_size", kind, size)
	if family != null:
		theme.set_font(&"font", kind, family)
	if colour != null:
		theme.set_color(&"font_color", kind, colour)


## A line layout: its gap, and how it packs and lines up, in the flex layout's own constants.
static func line(theme: Theme, type: StringName, base: StringName, gap: int, justify: int = START, align: int = STRETCH) -> void:
	_vary(theme, type, base)
	theme.set_constant(&"gap", type, gap)
	theme.set_constant(&"justify", type, justify)
	theme.set_constant(&"align", type, align)


## Everything marked as chosen, from the look's own pressable: a toggle
## turned off, and a radio's and a segment's plain option, are the pressable
## unchanged; one turned on, a choice's chosen option and the chosen inline
## options are every state's box with a bar in this ink along one side, the
## padding kept - a mark of shape, never a hue alone. A radio carries its bar
## at its start and a segment along its foot, and the segments are stood as
## far apart as their boxes draw past their sides, so none is drawn onto its
## neighbour (theme_pressables.gd).
static func toggle(theme: Theme, mark: Variant, thick: float = 6.0) -> void:
	# the plain ones: the look's own pressable, unchanged
	for plain: StringName in [Pressables.TOGGLE_OFF, Pressables.RADIO, Pressables.SEGMENT]:
		_vary(theme, plain, Themes.PRESSABLE)
		# every state the look draws, its own box, so an option is dressed like every other press on the screen
		for state: StringName in theme.get_stylebox_list(Themes.PRESSABLE):
			theme.set_stylebox(state, plain, theme.get_stylebox(state, Themes.PRESSABLE))
	marked(theme, Pressables.TOGGLE_ON, mark, thick)
	marked(theme, Pressables.CHOICE_CHOSEN, mark, thick)
	# every chosen inline option, marked on the side it carries its bar, and drawn selected as it is drawn normal: the chosen look is the same whoever chose (press_local.gd)
	for chosen: StringName in Pressables.BARS:
		marked(theme, chosen, mark, thick, Pressables.BARS[chosen])
		theme.set_stylebox(&"selected", chosen, theme.get_stylebox(&"normal", chosen))
		theme.set_color(&"font_color_selected", chosen, theme.get_color(&"font_color_normal", Themes.PRESSABLE))
	Pressables.stand_apart(theme)


## A pressable under this type with a bar of this ink along one side of
## every state.
static func marked(theme: Theme, type: StringName, mark: Variant, thick: float = 6.0, side: Side = SIDE_BOTTOM) -> void:
	_vary(theme, type, Themes.PRESSABLE)
	# every state the pressable draws, its box laid under the bar
	for state: StringName in theme.get_stylebox_list(Themes.PRESSABLE):
		var under: StyleBox = theme.get_stylebox(state, Themes.PRESSABLE)
		# a state drawn in the mark's own colour carries the bar in its ink, or it would not show
		var lit: bool = state == &"glowing" or state == &"selected"
		var turned := layered(theme, [under, Paint.rule(Paint.under(StringName("font_color_" + state), Themes.PRESSABLE) if lit else mark, thick, side)])
		# every side's padding, kept as the box under had it
		for edge: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			turned.set_content_margin(edge, under.get_margin(edge))
		theme.set_stylebox(state, type, turned)


## A field: a typed line under this type, its box at rest and with the
## focus, its ink and caret - a variation of the engine's own LineEdit,
## which is what a field is.
static func field(theme: Theme, type: StringName, normal: StyleBox, focus: StyleBox, ink: Color) -> void:
	_vary(theme, type, &"LineEdit")
	theme.set_stylebox(&"normal", type, normal)
	theme.set_stylebox(&"focus", type, focus)
	theme.set_stylebox(&"read_only", type, normal)
	theme.set_color(&"font_color", type, ink)
	theme.set_color(&"caret_color", type, ink)


## A ground: a surface drawing this box, blurring what is behind it by so much.
static func ground(theme: Theme, type: StringName, box: StyleBox, blur: int = 0) -> void:
	_vary(theme, type, Themes.SURFACE)
	theme.set_stylebox(&"panel", type, box)
	theme.set_constant(&"blur", type, blur)


## A type made a variation of its base - never of itself: a type that is
## its own base is a loop the engine's lookup walks until memory runs out.
static func _vary(theme: Theme, type: StringName, base: StringName) -> void:
	if type != base:
		theme.set_type_variation(type, base)
