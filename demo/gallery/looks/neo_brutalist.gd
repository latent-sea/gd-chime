extends "res://demo/demo_theme.gd"

const Collections := preload("res://addons/gd_chime/theme_collections.gd")
const Charts := preload("res://addons/gd_chime/theme_charts.gd")
const Feedback := preload("res://addons/gd_chime/theme_feedback.gd")

## NEO-BRUTALISM. Raw, loud and unambiguous: a thick black border around
## everything, a hard black box offset down-right for a shadow, unblended
## primaries on a cream ground, square corners, and no tint, blur or blend
## anywhere.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It is the anti-corporate reaction to flat design's politeness: depth is
## a solid offset rectangle rather than a soft one, so a state is a
## GEOMETRIC shift the eye cannot miss - hover pushes the shadow further
## out, glowing goes hot pink with a bigger one, inert drops the fill for a
## dashed edge, and focus doubles the border with an outer black ring.

const PALETTE := {
	&"ground": Color("#f2ece0"),
	&"raised": Color("#fffdf5"),
	&"lit": Color("#ffe500"),
	&"ink": Color("#000000"),
	&"ink_soft": Color("#676358"),
	&"accent": Color("#ff2d95"),
	&"shade": Color(0.0, 0.0, 0.0, 0.55),
}
const BLACK := Color("#000000")
const WHITE := Color("#fffdf5")
const BLUE := Color("#2b5bff")
## The accent, deep enough to be read as a link's words on the paper.
const LINK_INK := Color("#e1006f")
const LIME := Color("#8bff3d")
const EDGE := 3.0

## A flat fill inside a thick black border, over a solid black box shoved
## this far down and right.
func block(fill: Color, drop: float, pad: float = 12.0) -> StyleBox:
	return Look.layered(self, [[Look.flat(BLACK), Vector2(drop, drop)], Look.flat(fill, {border = EDGE, border_colour = BLACK})], pad)


## A board's pieces (theme_feedback.gd), as brutalism builds them: a lane is a
## sheet of white paper in a black box with the page's hard drop, going lime
## with a bigger drop when it would take the card over it and a dashed edge
## when it would not; a card is a cream block, lemon under the pointer, its
## hole a dashed edge; an avatar is a lime square in a black box; a badge a
## sticker whose fill climbs cream, cream, lemon, pink, blue with its level,
## beside the bars of its mark; progress is a black track with a lime share.
func _board(doubled: StyleBox, heavy: Font, body: Font) -> void:
	var dashed := func(pad: float) -> StyleBox: return Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], pad)
	Look.pressable(self, Collections.LANE, {&"normal": block(PALETTE[&"raised"], 8.0, 14.0), &"hover": block(PALETTE[&"raised"], 8.0, 14.0), &"accepting": block(LIME, 12.0, 14.0), &"refusing": dashed.call(14.0)}, {&"normal": BLACK, &"hover": BLACK, &"accepting": BLACK, &"refusing": BLACK}, doubled)
	Look.pressable(self, Collections.BOARD_CARD, {&"normal": block(PALETTE[&"ground"], 5.0, 12.0), &"hover": block(PALETTE[&"lit"], 8.0, 12.0), &"lifted": dashed.call(12.0)}, {&"normal": BLACK, &"hover": BLACK, &"lifted": BLACK}, doubled)
	Look.ground(self, Feedback.AVATAR, Look.flat(LIME, {border = EDGE, border_colour = BLACK, pad = 5.0}))
	var fills: Array[Color] = [PALETTE[&"raised"], PALETTE[&"raised"], PALETTE[&"lit"], PALETTE[&"accent"], BLUE]
	# every level of a badge: its sticker's fill, and the black bars of its mark
	for level: int in Feedback.BADGES.size():
		var sticker := Feedback.Marked.new(Look.flat(fills[level], {border = EDGE, border_colour = BLACK}), level, BLACK, PALETTE[&"ink_soft"])
		sticker.set_content_margin_all(5.0)
		sticker.content_margin_left = 8.0 + Feedback.BARS * (Feedback.BAR_WIDTH + Feedback.BAR_GAP) + 6.0
		Look.ground(self, Feedback.BADGES[level], sticker)
	set_color(&"track", Feedback.PROGRESS_BAR, BLACK)
	set_color(&"line", Feedback.PROGRESS_BAR, LIME)
	set_constant(&"thick", Feedback.PROGRESS_BAR, 16)
	Look.words(self, Collections.BOARD_CARD_TITLE, 22, heavy, BLACK)
	Look.words(self, Collections.BOARD_CARD_META, 17, body, BLACK)
	Look.words(self, Feedback.AVATAR_INITIALS, 15, heavy, BLACK)
	Look.words(self, Feedback.BADGE_LABEL, 15, body, BLACK)
	# every part carries a hard drop, so the lanes and the cards in them stand a drop and more apart
	for line: StringName in [Collections.LANES, Collections.LANE_COLUMN]:
		set_constant(&"gap", line, 18)
	set_constant(&"gap", Collections.BOARD_CARD_COLUMN, 6)


func _init() -> void:
	super(PALETTE)
	var heavy := Look.font(["Arial Black", "Impact", "Segoe UI Black", "Verdana"], 900)
	var body := Look.font(["Verdana", "Segoe UI", "Tahoma"], 700)
	# the pressable: electric blue in a black box, the shadow growing on hover, hot pink when it is the one to press, a dashed outline when refused
	var boxes := {
		&"normal": block(BLUE, 6.0),
		&"hover": block(BLUE, 10.0),
		&"inert": Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 12.0),
		&"glowing": block(PALETTE[&"accent"], 12.0),
	}
	var inks := {&"normal": WHITE, &"hover": WHITE, &"inert": PALETTE[&"ink_soft"], &"glowing": BLACK}
	# the focus: a second black ring outside the border, so the edge reads doubled
	var doubled := Look.ring(BLACK, {width = EDGE, inset = -5.0})
	Look.pressable(self, Themes.PRESSABLE, boxes, inks, doubled, &"Control")
	# a link's words: the accent taken deeper, since an accent is a fill's colour and does not stand out as words on the page (faint_words.gd)
	set_color(&"font_color_normal", &"Link", LINK_INK)
	# a flap: a square lemon block in its own black box, no shadow and no radius, so the strip butts into one black-ruled band
	var current := Look.layered(self, [Look.flap(WHITE, {radius = 0.0, pad_top = 24.0, pad = 10.0, border = EDGE, border_colour = BLACK}), Paint.rule(&"raised", EDGE + 1.0)], 10.0)
	current.content_margin_top = 24.0
	Look.pressable(self, &"Tab", {
		&"normal": Look.flap(PALETTE[&"lit"], {radius = 0.0, pad_top = 10.0, pad = 10.0, border = EDGE, border_colour = BLACK}),
		&"hover": Look.flap(LIME, {radius = 0.0, pad_top = 10.0, pad = 10.0, border = EDGE, border_colour = BLACK}),
		&"inert": Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 10.0),
		&"glowing": Look.flap(PALETTE[&"accent"], {radius = 0.0, pad_top = 10.0, pad = 10.0, border = EDGE, border_colour = BLACK}),
		# the one stood on: taller, in the panel's cream, a cream rule wiping the border it shares with the panel
		&"current": current,
	}, {&"normal": BLACK, &"hover": BLACK, &"inert": PALETTE[&"ink_soft"], &"glowing": BLACK, &"current": BLACK}, doubled)
	# the panel the flaps are welded to: the same cream in the same black box
	Look.ground(self, &"TabPanel", Look.flat(WHITE, {border = EDGE, border_colour = BLACK, pad = 16.0}))
	# a chip: lemon, small drop; a filter reads as a sticker stuck on the page
	Look.pressable(self, &"Chip", {
		&"normal": block(PALETTE[&"lit"], 4.0, 8.0),
		&"hover": block(LIME, 7.0, 8.0),
		&"inert": Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 8.0),
		&"glowing": block(PALETTE[&"accent"], 9.0, 8.0),
	}, {&"normal": BLACK, &"hover": BLACK, &"inert": PALETTE[&"ink_soft"], &"glowing": BLACK}, doubled)
	# an inline link: no block at all, a thick underline under heavy words
	Look.pressable(self, &"NavInline", {
		&"normal": Look.layered(self, [Paint.underline(&"ink", EDGE)], 6.0),
		&"hover": Look.layered(self, [Paint.underline(&"accent", 5.0)], 6.0),
		&"inert": Look.nothing(),
		&"glowing": Look.layered(self, [Paint.underline(&"accent", 6.0)], 6.0),
	}, {&"normal": BLACK, &"hover": BLACK, &"inert": PALETTE[&"ink_soft"], &"glowing": PALETTE[&"accent"]}, doubled)
	# the cards: cream in a black box on the white paper, lemon under the pointer
	for card: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, card, {
			&"normal": block(PALETTE[&"ground"], 6.0),
			&"hover": block(PALETTE[&"lit"], 10.0),
			&"inert": Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 12.0),
			&"glowing": block(PALETTE[&"accent"], 12.0),
		}, {&"normal": BLACK, &"hover": BLACK, &"inert": PALETTE[&"ink_soft"], &"glowing": BLACK}, doubled)
	# a value read back against its neighbours: lime, so a comparison is a third primary
	Look.pressable(self, &"Relative", {
		&"normal": block(LIME, 5.0, 10.0),
		&"hover": block(LIME, 9.0, 10.0),
		&"inert": Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 10.0),
		&"glowing": block(PALETTE[&"accent"], 11.0, 10.0),
	}, {&"normal": BLACK, &"hover": BLACK, &"inert": PALETTE[&"ink_soft"], &"glowing": BLACK}, doubled)
	# the words: one heavy sans throughout, black on everything, titles in the blackest weight
	set_default_font(body)
	default_font_size = 22
	set_color(&"font_color", &"Label", BLACK)
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, BLACK)
	Look.words(self, Themes.FACE, 26, body, BLACK)
	Look.words(self, Themes.REASON, 19, body, PALETTE[&"ink_soft"])
	Look.words(self, Themes.WORDS, 36, heavy, BLACK)
	Look.words(self, Themes.TITLE, 28, heavy, BLACK)
	Look.words(self, LINE, 22, body, BLACK)
	Look.words(self, READOUT, 21, body, BLACK)
	Look.words(self, Themes.NUMBER, 92, heavy, BLACK)
	# the grounds: every captioned box is white paper in a black box with the same hard drop
	Look.ground(self, Themes.RAISED, Look.layered(self, [[Look.flat(BLACK), Vector2(8.0, 8.0)], Look.flat(PALETTE[&"raised"], {border = EDGE, border_colour = BLACK})], 16.0))
	Look.ground(self, Themes.CARD, Look.layered(self, [[Look.flat(BLACK), Vector2(6.0, 6.0)], Look.flat(PALETTE[&"lit"], {border = EDGE, border_colour = BLACK})], 12.0))
	Look.ground(self, PANEL, Look.layered(self, [[Look.flat(BLACK), Vector2(12.0, 12.0)], Look.flat(PALETTE[&"raised"], {border = 5.0, border_colour = BLACK})], 26.0))
	Look.ground(self, Themes.SURFACE, Look.flat(PALETTE[&"raised"], {border = EDGE, border_colour = BLACK}))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# an empty crate and a bare collection: the dashed edge again, nothing filled
	for hollow: StringName in [&"CardEmpty", &"Collection"]:
		Look.ground(self, hollow, Look.layered(self, [Paint.dashed(&"ink_soft", EDGE, 9.0, 7.0)], 14.0))
	# a text field: white, sunk into its own thicker border, no drop - it takes rather than gives; a LineEdit draws its own normal box, not a surface's panel
	set_type_variation(&"Field", &"LineEdit")
	for state: StringName in [&"normal", &"focus", &"read_only"]:
		set_stylebox(state, &"Field", Look.flat(WHITE, {border = 5.0 if state == &"focus" else EDGE, border_colour = BLACK, pad = 10.0}))
	set_color(&"font_color", &"Field", BLACK)
	set_color(&"caret_color", &"Field", PALETTE[&"accent"])
	# lines drawn: black, as thick and plain as the borders
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, BLACK)
	set_color(&"link", &"Graph", PALETTE[&"ink_soft"])
	# the spacing: wide gaps, because every part carries a shadow that must not land on its neighbour
	for line: StringName in [Themes.ROW, Themes.COLUMN, Themes.TILES]:
		set_constant(&"gap", line, 18)
	# the pulse: a hard fast blink, not a fade
	set_constant(&"period", Themes.PULSE, 700)
	set_constant(&"depth", Themes.PULSE, 90)
	# the strip: no gutter at all and bottom-aligned, so the flaps butt into one black-ruled band and the current one grows upward
	Look.line(self, &"TabStrip", Themes.ROW, 0, Look.START, Look.END)
	Look.line(self, &"TabSet", Themes.COLUMN, 0)
	# the two spacings the arrangement uses: blocks butting, and blocks a chasm apart
	Look.line(self, &"Butt", Themes.ROW, 0)
	Look.line(self, &"ButtDown", Themes.COLUMN, 0)
	Look.line(self, &"Chasm", Themes.ROW, 54)
	# a grid of slabs: cells of mixed span, butting, no gutter
	set_type_variation(&"Slabs", &"Container")
	set_constant(&"gap", &"Slabs", 0)
	set_constant(&"row_gap", &"Slabs", 0)
	set_constant(&"least_column", &"Slabs", 240)
	# the stamp stuck on a cell
	Look.words(self, &"Stamp", 27, heavy, BLACK)
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	_board(doubled, heavy, body)
	# brutalism refuses easing: a thing is there or it is not, and what does move slides in flat from the side - the quick duration is nothing at all, so going and restyling are instant
	moves({&"quick": 0, &"normal": 90, &"slow": 140, Motion.STAGGER: 0}, {Motion.ENTER: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"normal"], Motion.EXIT: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"normal"], Motion.EMPHASIS: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"slow"], Motion.RESTYLE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"]}, {&"when": Transition.FROM_RIGHT, &"each": Transition.FROM_LEFT})
