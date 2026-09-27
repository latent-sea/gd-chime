extends "res://demo/demo_theme.gd"
const Navigation := preload("res://addons/gd_chime/theme_navigation.gd")
const Charts := preload("res://addons/gd_chime/theme_charts.gd")

## DARK-MODE HUD. The instrument panel: a near-black ground with a blue
## tint, thin luminous cyan lines, and corner brackets instead of borders -
## a frame is implied by its four corners, never closed - so the display
## reads as light emitted in the dark rather than paper laid on a desk.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Its rules: a ground is a barely-there translucent panel, every edge is
## one pixel, a glow is bloom - a cyan wash, a cyan edge, a cyan halo - and
## meta text is monospaced while words are a geometric sans. Cheap to draw
## and unmistakably a machine's; weak at density, because brackets leave a
## panel's middle edges unmarked and a crowded screen loses its divisions.

const PALETTE := {
	&"ground": Color("#07090d"),
	&"raised": Color("#0c1119"),
	&"lit": Color("#16202b"),
	&"ink": Color("#dbe9f2"),
	&"ink_soft": Color("#7c909d"),
	&"accent": Color("#22d3ee"),
	&"shade": Color(0.02, 0.03, 0.05, 0.72),
	# the focus: pure white, brighter than any ink - named, because it is painted, and a painter reads it by name
	&"white": Color("#ffffff"),
}
const CYAN := Color("#22d3ee")
## The line at rest: one pixel at about seven tenths, so it glows rather than rules.
const CYAN_LINE := Color(0.13, 0.83, 0.93, 0.7)
const CYAN_DIM := Color(0.13, 0.83, 0.93, 0.3)
const WHITE := Color("#ffffff")
## A ground: white at four hundredths, the least a panel can be and still be one.
const FILM := Color(1.0, 1.0, 1.0, 0.04)
const FILM_LIT := Color(1.0, 1.0, 1.0, 0.09)
## Measured text: a cool pale blue, so the cyan is left to mark what a block is about.
const METER := Color("#9fb8c6")


func _init() -> void:
	super(PALETTE)
	var mono := Look.font(["Consolas", "Courier New"])
	var sans := Look.font(["Bahnschrift", "Segoe UI", "Arial"])
	_pressables()
	_tabs()
	_grounds()
	_words(mono, sans)
	# every drawn readout: the luminous line; the graph's links fainter
	for drawn: StringName in Charts.DRAWN:
		set_color(&"line", drawn, CYAN_LINE)
	set_color(&"link", &"Graph", CYAN_DIM)
	# a pulse: quicker and deeper than the placeholder, the way a telltale blinks
	set_constant(&"period", Themes.PULSE, 900)
	set_constant(&"depth", Themes.PULSE, 70)
	_lines()
	# the toggle's two looks and the inline options', from this look's own pressable: on and chosen are marked
	Look.toggle(self, &"accent")
	# a readout boots rather than appears: each line snaps in on an expo curve, well behind the one before it
	moves({&"quick": 80, &"normal": 160, &"slow": 260, Motion.STAGGER: 110}, {Motion.ENTER: [Tween.TRANS_EXPO, Tween.EASE_OUT, &"normal"], Motion.EXIT: [Tween.TRANS_EXPO, Tween.EASE_IN, &"quick"], Motion.MOVE: [Tween.TRANS_EXPO, Tween.EASE_OUT, &"normal"], Motion.EMPHASIS: [Tween.TRANS_EXPO, Tween.EASE_OUT, &"slow"], Motion.RESTYLE: [Tween.TRANS_EXPO, Tween.EASE_OUT, &"quick"]}, {&"when": Transition.FADE, &"each": Transition.FROM_LEFT})



## Every pressable: a bracketed film at rest, a brighter bracket and a
## lighter film on hover, dim grey when refused, and bloom when prompted.
func _pressables() -> void:
	Look.pressable(self, Themes.PRESSABLE, _boxes(14.0, 10.0), {inks = _inks(), focus = _focus(16.0), base = &"Control"})
	# an inline link and a chip: no film, the brackets alone, so a bar of them reads as one strip
	for bare: StringName in [&"NavInline", &"Chip"]:
		var boxes := {
			&"normal": Look.layered(self, [Paint.brackets(Paint.faded(&"accent", 0.7), 1.0, 9.0, 2.0)], 9.0),
			&"hover": Look.layered(self, [Look.flat(FILM), Paint.brackets(&"accent", 2.0, 11.0, 2.0)], 9.0),
			&"inert": Look.layered(self, [Paint.brackets(Paint.faded(&"ink_soft", 0.55), 1.0, 9.0, 2.0)], 9.0),
			&"glowing": _bloom(9.0),
		}
		Look.pressable(self, bare, boxes, {inks = _inks(), focus = _focus(11.0)})
	# a card in a list or a grid: longer arms, more air, the same language at size
	for panel: StringName in [&"CardList", &"CardTile", &"CardDense"]:
		Look.pressable(self, panel, _boxes(18.0, 14.0), {inks = _inks(), focus = _focus(20.0)})


## A pressable's four states, its brackets this long and this much air inside.
func _boxes(arm: float, pad: float) -> Dictionary:
	return {
		&"normal": Look.layered(self, [Look.flat(FILM), Paint.brackets(Paint.faded(&"accent", 0.7), 1.0, arm, 2.0)], pad),
		&"hover": Look.layered(self, [Look.flat(FILM_LIT), Paint.brackets(&"accent", 2.0, arm + 2.0, 2.0)], pad),
		&"inert": Look.layered(self, [Paint.brackets(Paint.faded(&"ink_soft", 0.55), 1.0, arm, 2.0)], pad),
		&"glowing": _bloom(pad),
	}


## The tabs: bracketed flaps on the top edge of the centre panel. A flap at
## rest is a dim bracket over the same faint film the panel is made of; the
## one you are on keeps that film, brackets brighter, stands taller and
## carries a lit cyan rule along its foot, so the run of brackets breaks
## there and the flap reads as part of the panel below it.
func _tabs() -> void:
	var boxes := {
		&"normal": _flap([Look.flat(FILM), Paint.brackets(Paint.faded(&"accent", 0.3), 1.0, 9.0, 2.0)], 12.0),
		&"hover": _flap([Look.flat(FILM_LIT), Paint.brackets(&"accent", 2.0, 11.0, 2.0)], 12.0),
		&"inert": _flap([Paint.brackets(Paint.faded(&"ink_soft", 0.55), 1.0, 9.0, 2.0)], 12.0),
		&"glowing": _flap([_bloom(-1.0), Paint.brackets(&"accent", 2.0, 11.0, 2.0)], 12.0),
		&"current": _flap([Look.flat(FILM), Paint.brackets(&"accent", 2.0, 13.0, 2.0), Paint.rule(&"accent", 2.0, SIDE_BOTTOM, 1.0)], 22.0),
	}
	var inks := _inks()
	inks[&"current"] = WHITE
	Look.pressable(self, Navigation.TAB, boxes, {inks = inks, focus = _focus(11.0)})
	Look.ground(self, Navigation.TAB_PANEL, Look.layered(self, [Look.flat(FILM), Paint.brackets(Paint.faded(&"accent", 0.7), 1.0, 16.0, 3.0)], 14.0))
	Look.line(self, Navigation.TAB_SET, Themes.COLUMN, {gap = 0})


## One flap: these layers, this much air above the words and ten either
## side - the top pad is what makes the current flap the taller one.
func _flap(layers: Array, pad_top: float) -> StyleBox:
	var box := Look.layered(self, layers, 10.0)
	box.content_margin_top = pad_top
	return box


## The prompted state: a cyan wash behind a cyan edge with a cyan halo.
func _bloom(pad: float) -> StyleBox:
	return Look.flat(Color(0.13, 0.83, 0.93, 0.25), {border = 2.0, border_colour = CYAN, shadow = 10.0, shadow_colour = Color(0.13, 0.83, 0.93, 0.45), pad = pad})


## The ink in each state: pale at rest, white when lit or prompted, grey when refused.
func _inks() -> Dictionary:
	return {&"normal": PALETTE[&"ink"], &"hover": WHITE, &"inert": PALETTE[&"ink_soft"], &"glowing": WHITE}


## The focus: a bright white bracket set over the state's own.
func _focus(arm: float) -> StyleBox:
	return Look.layered(self, [Paint.brackets(&"white", 2.0, arm, 0.0)])


## The grounds: every panel a film under brackets, except the pop-up's
## sheet, which closes its frame because it is the one thing on the screen.
func _grounds() -> void:
	Look.ground(self, Themes.RAISED, Look.layered(self, [Look.flat(FILM), Paint.brackets(Paint.faded(&"accent", 0.7), 1.0, 16.0, 3.0)], 14.0))
	Look.ground(self, Themes.CARD, Look.layered(self, [Look.flat(FILM), Paint.brackets(Paint.faded(&"accent", 0.3), 1.0, 12.0, 3.0)], 12.0))
	Look.ground(self, Themes.SURFACE, Look.flat(FILM))
	Look.ground(self, SHADE, Look.flat(PALETTE[&"shade"]))
	# the pop-up and the things that read as one closed instrument
	for framed: StringName in [PANEL, &"Moment", &"Bubble"]:
		Look.ground(self, framed, Look.flat(PALETTE[&"raised"], {border = 1.0, border_colour = CYAN_LINE, pad = 20.0}))
	# the open grounds: brackets alone, nothing filled behind them
	for open_ground: StringName in [&"Collection", &"Board", &"Matrix", &"Graph", &"CardEmpty", &"Countdown"]:
		Look.ground(self, open_ground, Look.layered(self, [Paint.brackets(Paint.faded(&"accent", 0.3), 1.0, 14.0, 2.0)], 12.0))
	# the text field: a film under a single lit underline, the way an entry reads on an instrument
	Look.field(self, &"Field", {normal = Look.layered(self, [Look.flat(FILM), Paint.underline(&"accent", 1.0, 0.0)], 10.0), focus = Look.layered(self, [Look.flat(FILM), Paint.underline(&"white", 2.0, 0.0)], 10.0)}, Color.WHITE)


## The words: a geometric sans for what is read, monospace for what is
## measured - a reason and a readout are the machine talking.
func _words(mono: Font, sans: Font) -> void:
	set_default_font(sans)
	default_font_size = 24
	Look.words(self, Themes.FACE, 26, {font = sans, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.WORDS, 34, {font = sans, colour = WHITE})
	Look.words(self, Themes.REASON, 18, {font = mono, colour = PALETTE[&"ink_soft"]})
	Look.words(self, READOUT, 20, {font = mono, colour = METER})
	Look.words(self, LINE, 22, {font = mono, colour = PALETTE[&"ink"]})
	Look.words(self, Themes.TITLE, 20, {font = sans, colour = CYAN})
	Look.words(self, Themes.NUMBER, 88, {font = mono, colour = WHITE})


## The spacing: wide gaps, because a bracket needs empty ground around it
## to read as a corner rather than as part of its neighbour.
func _lines() -> void:
	for line: StringName in [Themes.ROW, Themes.COLUMN]:
		set_constant(&"gap", line, 16)
	Look.line(self, Themes.TILES, Themes.ROW, {gap = 16})
	Look.line(self, &"Chips", Themes.ROW, {gap = 10})
	# the flaps sit along the baseline, packed from the left, close enough to read as one edge
	Look.line(self, Navigation.TAB_STRIP, Themes.ROW, {gap = 6, justify = Look.START, align = Look.END})
	Look.line(self, &"Controls", Themes.ROW, {gap = 14, justify = Look.BETWEEN, align = Look.CENTER})
	Look.line(self, &"InstructionBar", Themes.ROW, {gap = 18, justify = Look.START, align = Look.CENTER})
