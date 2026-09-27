extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")
const Collections := preload("res://addons/gd_chime/theme_collections.gd")

## FLAT DESIGN. The reaction against imitation: no gradient, no shadow, no
## texture, no border; solid colour, crisp type and geometry alone carry
## meaning, and a state is a change of colour and nothing else.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Cheap to draw and honest, and brutal on affordance: a button is a
## rectangle of colour and only its colour says it can be pressed. That is
## the weakness Material and neumorphism each answer in their own way.

const PALETTE := {
	&"ground": Color("#ecf0f1"),
	&"raised": Color("#ffffff"),
	&"lit": Color("#d6dde2"),
	&"ink": Color("#2c3e50"),
	&"ink_soft": Color("#6b7778"),
	&"accent": Color("#e67e22"),
	&"shade": Color(0.17, 0.24, 0.31, 0.5),
}
const BLUE := Color("#207ab6")
const BLUE_DEEP := Color("#175f8c")
const WHITE := Color("#ffffff")
## The accent, deep enough to be read as a link's words on the page.
const LINK_INK := Color("#b35f14")


func _init() -> void:
	super(PALETTE)
	# a pressable: a solid block, deeper on hover, bare on inert, the accent when glowing; the focus a thin inner ring
	var boxes := {&"normal": Look.flat(BLUE, {pad = 10.0}), &"hover": Look.flat(BLUE_DEEP, {pad = 10.0}), &"inert": Look.flat(PALETTE[&"lit"], {pad = 10.0}), &"glowing": Look.flat(PALETTE[&"accent"], {pad = 10.0})}
	var inks := {&"normal": WHITE, &"hover": WHITE, &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE}
	Look.pressable(self, Themes.PRESSABLE, boxes, inks, Look.ring(WHITE, {width = 2.0, inset = 4.0}), &"Control")
	# a tab: a square flap in the pale block colour; the current one in the panel's white, taller, merging into it
	Look.pressable(self, &"Tab", {&"normal": Look.flap(PALETTE[&"lit"], {radius = 0.0, pad_top = 8.0, pad = 10.0}), &"hover": Look.flap(PALETTE[&"raised"], {radius = 0.0, pad_top = 8.0, pad = 10.0}), &"inert": Look.flap(PALETTE[&"lit"], {radius = 0.0, pad_top = 8.0, pad = 10.0}), &"glowing": Look.flap(PALETTE[&"accent"], {radius = 0.0, pad_top = 8.0, pad = 10.0}), &"current": Look.flap(PALETTE[&"raised"], {radius = 0.0, pad_top = 16.0, pad = 10.0})}, {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE, &"current": BLUE_DEEP}, Look.ring(PALETTE[&"ink"], {width = 2.0}))
	Look.ground(self, &"TabPanel", Look.flat(PALETTE[&"raised"], {pad = 12.0}))
	Look.line(self, &"TabStrip", Themes.ROW, 4, Look.START, Look.END)
	Look.line(self, &"TabSet", Themes.COLUMN, 0)
	# a chip and an inline link: words in the accent's family, no block at all
	for bare: StringName in [&"Chip", &"NavInline"]:
		Look.pressable(self, bare, {&"normal": Look.nothing(), &"hover": Look.flat(PALETTE[&"lit"]), &"inert": Look.nothing(), &"glowing": Look.flat(PALETTE[&"accent"])}, {&"normal": BLUE_DEEP, &"hover": BLUE_DEEP, &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE}, Look.ring(BLUE_DEEP, {width = 2.0}))
	# the words: one sans family at four sizes, the ink on the ground
	var sans := Look.font(["Segoe UI", "Helvetica", "Arial"])
	set_default_font(sans)
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	Look.words(self, Themes.WORDS, 34, Look.font(["Segoe UI", "Helvetica", "Arial"], 600), PALETTE[&"ink"])
	Look.words(self, Themes.TITLE, 22, Look.font(["Segoe UI", "Helvetica", "Arial"], 700), BLUE_DEEP)
	Look.words(self, READOUT, 20, sans, PALETTE[&"ink_soft"])
	# the grounds: white cards on the pale ground, a shade under a pop-up, the sheet white
	# a link's words: the accent taken deeper, since an accent is a fill's colour and does not stand out as words on the page (faint_words.gd)
	set_color(&"font_color_normal", &"Link", LINK_INK)
	Look.ground(self, Themes.RAISED, Look.flat(PALETTE[&"raised"], {pad = 12.0}))
	Look.ground(self, Themes.CARD, Look.flat(PALETTE[&"lit"]))
	# a card that can be pressed: a white card on the pale ground, not a blue button - the pressable's white words on a pale panel inside a card cannot be read (faint_words.gd)
	for card: StringName in [Collections.CARD_LIST, Collections.CARD_TILE, Collections.CARD_DENSE]:
		Look.pressable(self, card, {&"normal": Look.flat(PALETTE[&"raised"], {pad = 12.0}), &"hover": Look.flat(PALETTE[&"lit"], {pad = 12.0}), &"inert": Look.flat(PALETTE[&"lit"], {pad = 12.0}), &"glowing": Look.flat(PALETTE[&"raised"], {border = 2.0, border_colour = PALETTE[&"accent"], pad = 12.0})}, {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink_soft"], &"glowing": PALETTE[&"ink"]}, Look.ring(BLUE_DEEP, {width = 2.0}))
	Look.ground(self, PANEL, Look.flat(PALETTE[&"raised"], {pad = 24.0}))
	Look.ground(self, Themes.SURFACE, Look.flat(PALETTE[&"raised"]))
	# the typed field: a pale block, a blue edge while it has the focus
	Look.field(self, &"Field", Look.flat(PALETTE[&"lit"], {pad = 8.0}), Look.flat(PALETTE[&"raised"], {border = 2.0, border_colour = BLUE, pad = 8.0}), PALETTE[&"ink"])
	# lines drawn: the ink, the graph's links soft
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, BLUE_DEEP)
	# the spacing scale: a little more air than the placeholder
	for line: StringName in [Themes.ROW, Themes.COLUMN]:
		set_constant(&"gap", line, 16)
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# flat design admits no illusion of depth, so a change is quick, straight and over
	moves({&"quick": 60, &"normal": 120, &"slow": 200, Motion.STAGGER: 20}, {Motion.ENTER: [Tween.TRANS_LINEAR, Tween.EASE_OUT, &"quick"], Motion.EXIT: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_SINE, Tween.EASE_OUT, &"normal"], Motion.RESTYLE: [Tween.TRANS_LINEAR, Tween.EASE_IN, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.FADE})
