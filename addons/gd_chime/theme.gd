extends Theme

const Motion := preload("motion.gd")
const MotionTokens := preload("motion_tokens.gd")
const Transition := preload("components/primitives/transition.gd")
const Placeholders := preload("theme_placeholders.gd")

## The look, as the engine's own Theme, built from a palette: placeholder
## defaults for exactly the types the primitives and the floor's recipes
## ask for.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A palette is a dictionary of named colours - ours, in whatever form it came
## from: typed in, read from a file, chosen in settings. This turns one into
## the engine's Theme. Set it on the root and every Control under it is told,
## the way each is told it was resized, and repaints from it. No bell is
## involved. A player choosing a palette is a new one of these on the root.
##
## Every colour goes in under one type, LOOK, so a screen asks for a colour by
## name and never has to know which engine control it happens to be painting.
##
## THIS FILE IS THE FLOOR'S OWN VOCABULARY and nothing else: the palette, the
## types every other style is a variation of - a pressable, a row, a column,
## a grid, tiles, a surface - the kinds of words, and the tokens an
## application draws on. The component FAMILIES are dressed by a file each,
## by family and never by the application that drove them: buttons and
## pressables, fields, tables, overlays, charts, collections, navigation,
## feedback. Each is handed this theme as it is built, puts its own types in
## and holds nothing; the order below is what they read of each other, the
## pressable's boxes first because every family builds from them.
##
## A PRIMITIVE ASKS THE LOOK BY ITS STYLE, a Theme name, and holds no look of
## its own. A pressable draws, under its style, the stylebox of its state -
## normal, hover, inert, glowing - the focus stylebox over it while the focus
## shows, a ring inside its edge, and its words in the state's font colour; a row or a column takes
## its gap, justify and align; a grid its gaps and least column; a surface
## its panel; a text its size and colour as a kind of words. A RECIPE OWNS
## ITS STRUCTURAL VARIANTS: every style a floor recipe names is registered
## by its family as a variation of its base, so a look that sets nothing
## still lays every recipe out and draws it; a look changes the values.
##
## THE ENGINE SCALES TO THE WINDOW (project.godot: the canvas is drawn at
## the base size and stretched), so a size is written ONCE, here, in base
## pixels, and never measured from a control's rect.
##
## This folder ships a neutral palette so that it runs and its demos are
## legible without a consumer. It is not a design: greys, one accent, and
## enough contrast to read. The look belongs to whoever uses this. Nothing
## here is a demo's: a demo builds its own Theme over these defaults
## (Theme.merge_with) and adds the types it draws.

const LOOK := &"Look"
## The primitives' styles: the types every family varies.
const PRESSABLE := &"Pressable"
const ROW := &"Row"
const COLUMN := &"Column"
const GRID := &"Grid"
const SURFACE := &"Surface"
const TILES := &"Tiles"
const PULSE := &"Pulse"
const KEYFRAMES := &"Keyframes"
## The kinds of words the floor's recipes draw, variations of Label, and running words as a paragraph.
const FACE := &"Face"
const REASON := &"Reason"
const WORDS := &"Words"
const PARAGRAPH := &"Paragraph"
## What an application names a thing and says a figure in: a title over what it titles, and a number big enough to read across the room.
const TITLE := &"Title"
const NUMBER := &"Number"
const SIZES := {FACE: 28, REASON: 20, WORDS: 36, TITLE: 22, NUMBER: 90}
## The grounds an application stands its own content on: a panel raised off the page, and a card on it.
const RAISED := &"Raised"
const CARD := &"Card"
## A row packing its parts to the middle, for a line of presses under what they are about.
const CENTRED := &"Centred"
## The rule between parts: its base, which the placeholders are read under, across a column and down a row.
const DIVIDER := &"Divider"
const DIVIDER_ACROSS := &"DividerAcross"
const DIVIDER_DOWN := &"DividerDown"
## Loading's mark, the shape standing in for what has not landed, a notification (theme_feedback.gd).
const LOADING := &"Loading"
const PLACEHOLDER := &"Placeholder"
const NOTICE := &"Notice"

const NEUTRAL := {
	&"ground": Color(0.10, 0.11, 0.13),
	&"raised": Color(0.16, 0.17, 0.20),
	&"lit": Color(0.28, 0.30, 0.35),
	&"ink": Color(0.90, 0.92, 0.95),
	&"ink_soft": Color(0.62, 0.66, 0.72),
	&"accent": Color(0.85, 0.66, 0.28),
	&"shade": Color(0.10, 0.11, 0.13, 0.6),
}
## A pressable's ground and words in each state, as palette names.
const GROUNDS := {&"normal": &"raised", &"hover": &"lit", &"inert": &"ground", &"glowing": &"accent", &"selected": &"accent"}
const INKS := {&"normal": &"ink", &"hover": &"ink", &"inert": &"ink_soft", &"glowing": &"ground", &"selected": &"ground"}
## Every family, in the order they read each other: the pressable's boxes
## first, since every other family builds its own presses from them.
const FAMILIES: Array[GDScript] = [preload("theme_pressables.gd"), preload("theme_fields.gd"), preload("theme_tables.gd"), preload("theme_overlays.gd"), preload("theme_charts.gd"), preload("theme_feedback.gd"), preload("theme_collections.gd"), preload("theme_navigation.gd")]


func _init(palette: Dictionary) -> void:
	Placeholders.put(self)
	# what swaps, and how it arrives and goes until a look says otherwise
	Transition.defaults(self, {&"when": Transition.FADE, &"each": Transition.GROW, &"overlay": Transition.FADE, &"panel": Transition.FROM_RIGHT, &"by_shape": Transition.FADE})
	# how things move, until a look says otherwise: brisk, eased out on the way in and in on the way out
	MotionTokens.write(self, {&"quick": 90, &"normal": 180, &"slow": 360, Motion.STAGGER: 40}, {Motion.ENTER: [Tween.TRANS_CUBIC, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_CUBIC, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_CUBIC, Tween.EASE_IN_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_BACK, Tween.EASE_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_SINE, Tween.EASE_OUT, &"quick"]})
	# every named colour, put under the one type a screen asks by
	for name: StringName in palette:
		set_color(name, LOOK, palette[name])
	default_font_size = 24
	# plain words, under no kind, in the ink: the engine's own default is white
	set_color(&"font_color", &"Label", palette[&"ink"])
	# every kind of words, a Label sized once
	for kind: StringName in SIZES:
		set_type_variation(kind, &"Label")
		set_font_size(&"font_size", kind, SIZES[kind])
	# running words: as big as a face's
	set_type_variation(PARAGRAPH, &"Label")
	set_font_size(&"font_size", PARAGRAPH, SIZES[FACE])
	# a row and a column: the gap between parts, and how they are packed and lined up, in the line layout's words
	for line: StringName in [ROW, COLUMN]:
		set_type_variation(line, &"Container")
		set_constant(&"gap", line, 12)
		set_constant(&"justify", line, 0)
		set_constant(&"align", line, 6)
	# tiles: a row that wraps
	set_type_variation(TILES, ROW)
	set_constant(&"wrap", TILES, 1)
	set_type_variation(GRID, &"Container")
	set_constant(&"gap", GRID, 12)
	set_constant(&"row_gap", GRID, 12)
	set_constant(&"least_column", GRID, 240)
	# a surface: a flat panel on the raised ground; a raised panel the same, and a card on it in the lit ground
	set_type_variation(SURFACE, &"Control")
	set_type_variation(RAISED, SURFACE)
	set_type_variation(CARD, SURFACE)
	for ground: Array in [[SURFACE, &"raised"], [RAISED, &"raised"], [CARD, &"lit"]]:
		var panel := StyleBoxFlat.new()
		panel.bg_color = palette[ground[1]]
		set_stylebox(&"panel", ground[0], panel)
	# a row packing its parts to the middle
	set_type_variation(CENTRED, ROW)
	set_constant(&"justify", CENTRED, 1)
	# a pulse: its period in milliseconds, and how far it fades in hundredths; a track of keyframes, which has nothing of its own to draw
	for drawn: StringName in [PULSE, KEYFRAMES]:
		set_type_variation(drawn, &"Control")
	set_constant(&"period", PULSE, 1200)
	set_constant(&"depth", PULSE, 60)
	# how wide the band at a scroll's edge is, and how fast a carry there drags it, in base pixels a second
	set_constant(&"drag_edge", &"Scroll", 64)
	set_constant(&"drag_edge_speed", &"Scroll", 900)
	# a strip's cover where more lies beyond an end: the ground, ruled in the soft ink on the side facing the things
	for side: Array in [[&"more_before", SIDE_RIGHT], [&"more_after", SIDE_LEFT]]:
		var cover := StyleBoxFlat.new()
		cover.bg_color = palette[&"ground"]
		cover.border_color = palette[&"ink_soft"]
		cover.set_border_width(side[1], 4)
		set_stylebox(side[0], &"Scroll", cover)
	# the rule between parts: a line in the soft ink through the middle of the air either side of it, across a column and down a row
	set_type_variation(DIVIDER, SURFACE)
	for down: bool in [false, true]:
		var line := StyleBoxLine.new()
		line.color = palette[&"ink_soft"]
		line.thickness = get_constant(&"rule", DIVIDER)
		line.vertical = down
		line.content_margin_left = get_constant(&"air", DIVIDER) if down else 0.0
		line.content_margin_right = get_constant(&"air", DIVIDER) if down else 0.0
		line.content_margin_top = 0.0 if down else get_constant(&"air", DIVIDER)
		line.content_margin_bottom = 0.0 if down else get_constant(&"air", DIVIDER)
		set_type_variation(DIVIDER_DOWN if down else DIVIDER_ACROSS, DIVIDER)
		set_stylebox(&"panel", DIVIDER_DOWN if down else DIVIDER_ACROSS, line)
	# every family of pieces, dressed from the palette by a file of its own
	for dresses: GDScript in FAMILIES:
		dresses.dress(self, palette)
