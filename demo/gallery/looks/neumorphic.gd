extends "res://demo/demo_theme.gd"

const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## NEUMORPHISM (soft UI). One pale hue for everything: nothing is a
## different colour from the ground, so nothing has an edge. A control is
## the ground pushed out towards you - a white shadow up-left, a blue-grey
## one down-right - or pressed into it, the two swapped. No borders, no
## fills that differ, big radii, and a mid blue-grey ink throughout.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rules: normal is extruded, hover is extruded further, inert lies
## flat with the ground and goes soft in the ink, glowing is pressed in and
## takes the one warm accent, and focus is a faint inset ring. The cost is
## famous and real - every surface is the same value, so contrast comes
## from shadow alone and the ink carries the whole of the legibility.

const PALETTE := {
	&"ground": Color("#e0e5ec"),
	&"raised": Color("#e4e9f0"),
	&"lit": Color("#d7dee8"),
	&"ink": Color("#4a5a72"),
	&"ink_soft": Color("#516076"),
	&"accent": Color("#e8734a"),
	&"shade": Color(0.68, 0.72, 0.78, 0.55),
}
## The accent, deep enough to be read as a link's words on the ground.
const LINK_INK := Color("#b54017")
## The paired shadows every box is made of: the white above-left, the blue-grey below-right.
const LIGHT := Color("#ffffff")
const DARK := Color("#a3b1c6")
## The radii and the shadow spreads the language is written at.
const ROUND := 18.0
const SMALL := 14.0
const REST := 8.0
const LIFT := 13.0
## The one place the hue changes: a glowing control is pressed in and warmed.
const WARM := Color("#efdcd2")
## The wrapping line's name, as the floor spells it.
const TILES_LINE := &"Tiles"


func _init() -> void:
	super(PALETTE)
	var hue: Color = PALETTE[&"ground"]
	# the base pressable: extruded at rest, pushed further on hover, flat and soft when inert, pressed in and warm when glowing
	Look.pressable(self, Themes.PRESSABLE, _states(hue, ROUND, 16.0), _inks(), _inset(ROUND), &"Control")
	# a chip, a tab and the small choices: the same language at a smaller radius and a shorter shadow
	for small: StringName in [&"Chip", &"Picker", &"Choice", &"Relative"]:
		Look.pressable(self, small, _states(hue, SMALL, 11.0), _inks(), _inset(SMALL))
	# a link's words: the accent taken deeper, since an accent is a fill's colour and does not stand out as words on the page (faint_words.gd)
	set_color(&"font_color_normal", &"Link", LINK_INK)
	_tabs(hue)
	# a card in a list or a grid: a broad plate, so the extrusion is gentler over the bigger area
	for plate: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, plate, _states(hue, ROUND, 18.0), _inks(), _inset(ROUND))
	# an inline word and the play control: no plate at rest - a soft UI hides its links until touched
	for bare: StringName in [&"NavInline", &"NavPlay"]:
		var boxes := {&"normal": Look.flat(Color.TRANSPARENT, {radius = SMALL, pad = 10.0}), &"hover": Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = SMALL, spread = REST, pad = 10.0}), &"inert": Look.flat(Color.TRANSPARENT, {radius = SMALL, pad = 10.0}), &"glowing": Look.soft(self, WARM, {light = LIGHT, dark = DARK, radius = SMALL, spread = REST, sunken = true, pad = 10.0})}
		Look.pressable(self, bare, boxes, _inks(), _inset(SMALL))
	_words()
	_grounds(hue)
	_lines()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# a surface pressed out of the ground never snaps and never bounces: it eases into and out of every move
	moves({&"quick": 160, &"normal": 340, &"slow": 560, Motion.STAGGER: 60}, {Motion.ENTER: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"normal"], Motion.MOVE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"slow"], Motion.EMPHASIS: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_SINE, Tween.EASE_IN_OUT, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.FADE})



## The flaps. This language has no edges, so a flap cannot merge into a
## panel: the strip is soft chips on the bare surface, and the place you
## are on is the one chip pressed INTO it - the same hollow a typed line
## and the tray are. The panel is left plain, for an arrangement that
## carries its screens on the surface instead.
func _tabs(hue: Color) -> void:
	var boxes := _states(hue, SMALL, 11.0)
	# the hollow takes the palette's one darker value: swapped shadows alone are too quiet to say where you are
	boxes[&"current"] = Look.soft(self, PALETTE[&"lit"], {light = LIGHT, dark = DARK, radius = SMALL, spread = LIFT, sunken = true, pad = 11.0})
	var inks := _inks()
	inks[&"current"] = PALETTE[&"ink"]
	Look.pressable(self, &"Tab", boxes, inks, _inset(SMALL))
	Look.ground(self, &"TabPanel", Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = ROUND, spread = REST, pad = 18.0}))
	# the chips stand level, so the strip lines them up down the middle, not on a baseline
	Look.line(self, &"TabStrip", Themes.ROW, 18, Look.START, Look.STRETCH)
	Look.line(self, &"TabSet", Themes.COLUMN, 0)


## A pressable's four boxes at one radius and one padding: out, further out, flat, in.
func _states(hue: Color, radius: float, pad: float) -> Dictionary:
	return {
		&"normal": Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = radius, spread = REST, pad = pad}),
		&"hover": Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = radius, spread = LIFT, pad = pad}),
		&"inert": Look.flat(hue, {radius = radius, pad = pad}),
		&"glowing": Look.soft(self, WARM, {light = LIGHT, dark = DARK, radius = radius, spread = REST, sunken = true, pad = pad}),
	}


## The ink of each state: the mid blue-grey, soft when inert, warm when pressed in.
func _inks() -> Dictionary:
	return {&"normal": PALETTE[&"ink"], &"hover": PALETTE[&"ink"], &"inert": PALETTE[&"ink_soft"], &"glowing": PALETTE[&"accent"]}


## The focus: a faint ring set inside the edge, never a hard outline.
func _inset(radius: float) -> StyleBox:
	return Look.ring(Color(PALETTE[&"ink"], 0.35), {width = 2.0, radius = radius, inset = 5.0})


## The words: one soft sans throughout, the ink dark enough to carry the
## whole of the contrast, since no surface differs from any other.
func _words() -> void:
	var sans := Look.font(["Segoe UI", "Trebuchet MS", "Verdana"])
	var heavy := Look.font(["Segoe UI", "Trebuchet MS", "Verdana"], 600)
	set_default_font(sans)
	# plain words, under no kind at all, take the ink too: nothing here may be left at the engine's near-white
	set_color(&"font_color", &"Label", PALETTE[&"ink"])
	for kind: StringName in [Themes.FACE, Themes.REASON, Themes.WORDS, READOUT, LINE, Themes.TITLE, Themes.NUMBER]:
		set_color(&"font_color", kind, PALETTE[&"ink"])
	Look.words(self, Themes.FACE, 26, heavy, PALETTE[&"ink"])
	Look.words(self, Themes.REASON, 19, sans, PALETTE[&"ink_soft"])
	Look.words(self, Themes.WORDS, 32, heavy, PALETTE[&"ink"])
	Look.words(self, Themes.TITLE, 21, heavy, PALETTE[&"ink"])
	Look.words(self, READOUT, 21, sans, PALETTE[&"ink"])
	Look.words(self, LINE, 22, sans, PALETTE[&"ink"])
	Look.words(self, Themes.NUMBER, 84, Look.font(["Segoe UI", "Trebuchet MS", "Verdana"], 300), PALETTE[&"ink"])


## The grounds: every one is the same hue as the window, extruded to a
## different degree; only the shade under a pop-up is not.
func _grounds(hue: Color) -> void:
	Look.ground(self, Themes.SURFACE, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = ROUND, spread = REST, pad = 14.0}))
	Look.ground(self, Themes.RAISED, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = ROUND, spread = REST, pad = 18.0}))
	Look.ground(self, Themes.CARD, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = SMALL, spread = REST, pad = 14.0}))
	Look.ground(self, PANEL, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = 24.0, spread = 18.0, pad = 28.0}))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# a typed line is the engine's own field, named as one so the lookup finds these
	set_type_variation(&"Field", &"LineEdit")
	# the box it draws, so it takes a normal box, not a panel: a hollow pressed into the ground
	set_stylebox(&"normal", &"Field", Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = SMALL, spread = REST, sunken = true, pad = 12.0}))
	set_stylebox(&"focus", &"Field", _inset(SMALL))
	set_color(&"font_color", &"Field", PALETTE[&"ink"])
	set_color(&"caret_color", &"Field", PALETTE[&"accent"])
	# a bubble and an empty crate: pressed in, so each reads as a hollow in the ground
	for sunken: StringName in [&"Bubble", &"CardEmpty"]:
		Look.ground(self, sunken, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = SMALL, spread = REST, sunken = true, pad = 14.0}))
	# the tray the instruction lies in: the same hollow, the width of the window
	Look.ground(self, &"Tray", Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = ROUND, spread = REST, sunken = true, pad = 20.0}))
	# the broad collecting grounds: a shallow extrusion under whatever sits on them
	for broad: StringName in [&"Collection", &"Board", &"Matrix", &"Moment", &"Graph", &"Countdown"]:
		Look.ground(self, broad, Look.soft(self, hue, {light = LIGHT, dark = DARK, radius = ROUND, spread = 7.0, pad = 16.0}))


## The lines drawn and the spacing: shadows need room, so the gaps are wide.
func _lines() -> void:
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, PALETTE[&"ink"])
	set_color(&"link", &"Graph", PALETTE[&"ink_soft"])
	for line: StringName in [Themes.ROW, Themes.COLUMN, TILES_LINE]:
		set_constant(&"gap", line, 22)
	Look.line(self, &"Chips", Themes.TILES, 16)
	Look.line(self, &"Controls", Themes.ROW, 20, Look.CENTER)
	Look.line(self, &"InstructionBar", Themes.ROW, 22, Look.CENTER, Look.CENTER)
	set_constant(&"period", Themes.PULSE, 2000)
	set_constant(&"depth", Themes.PULSE, 35)
