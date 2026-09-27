extends RefCounted

## The figures and charts of a dashboard, as the floor's look draws them
## until a look says otherwise: a KPI card and its words, a bar chart's
## bars, a map's regions and the presses pinned on them, and the words a
## chart says when it has nothing to show.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## theme.gd builds the look and calls dress() once, with the palette it was
## given; this puts its types into that theme and holds nothing. Its numbers
## are placeholders, held by theme_placeholders.gd, and read here, never
## written.
##
## A chart draws in its style's inks: "line" for what is measured, "link"
## for what it is compared with and for edges, "fill" for an area. What is
## picked or current is told by a SHAPE - a rule down a bar's side, a ring
## round a pin - and never by a hue alone.
##
## It must never name a colour: every colour is the palette's, by name.

const KPI_CARD := &"KpiCard"
const KPI_SAYS := &"KpiSays"
const KPI_FIGURE := &"KpiFigure"
const KPI_CHANGE := &"KpiChange"
const TREND := &"KpiTrend"
const LINE_CHART := &"LineChart"
const SAMPLE := &"LineChartSample"
const EMPTY := &"Empty"
const BARS := &"BarChart"
const BAR := &"BarChartBar"
const TRACK := &"BarChartTrack"
const BAR_TEXT := &"BarChartWords"
const MAP := &"RegionMap"
const PIN := &"RegionMapPin"
const PIN_TEXT := &"RegionMapName"
const RANGE := &"DateRange"
## The lines a chart draws, each under its own type: a bar, a trace, a mark, a graph's edges, a line chart's line - and the palette's ink each takes.
const DRAWN := {&"Bar": &"ink", &"Trace": &"ink", &"Mark": &"ink", &"Graph": &"ink", LINE_CHART: &"ink"}
## A knockout bracket: the row of rounds, one round's column of ties - spread
## down it, so a later round's tie sits between the two that feed it - and a tie.
const BRACKET := &"Bracket"
const BRACKET_ROUND := &"BracketRound"
const TIE := &"Tie"
## The panel of presses a relationship graph stands over the node picked.
const GRAPH_PANEL := &"GraphPanel"
## Each kind of words: its size's placeholder, and its ink by palette name.
const KINDS := {KPI_SAYS: [&"says_size", &"ink_soft"], KPI_FIGURE: [&"figure_size", &"ink"], KPI_CHANGE: [&"change_size", &"ink"], EMPTY: [&"says_size", &"ink_soft"], BAR_TEXT: [&"says_size", &"ink"], PIN_TEXT: [&"says_size", &"ink"]}
## A card's and a pin's ground in each state, as palette names.
const GROUNDS := {&"normal": &"raised", &"hover": &"lit", &"inert": &"raised", &"glowing": &"accent", &"current": &"lit"}
const INKS := {&"normal": &"ink", &"hover": &"ink", &"inert": &"ink_soft", &"glowing": &"ground", &"current": &"ink"}
## A bar's ground in each state: none at rest, so the bars stand on the chart's own.
const BAR_GROUNDS := {&"normal": &"", &"hover": &"lit", &"inert": &"", &"glowing": &"accent", &"current": &"lit"}


## Every chart's and figure's type put into this theme, from this palette.
static func dress(theme: Theme, palette: Dictionary) -> void:
	var pad := float(theme.get_constant(&"pad", KPI_CARD))
	var rule := theme.get_constant(&"rule", BAR)
	# every line a chart draws: its own colour, the graph's fainter link, and an area under it in its ink faded by the placeholder's thousandths, so the line over it still reads
	for drawn: StringName in DRAWN:
		theme.set_type_variation(drawn, &"Control")
		theme.set_color(&"line", drawn, palette[DRAWN[drawn]])
		theme.set_color(&"link", drawn, palette[&"ink_soft"])
		var under: Color = palette[DRAWN[drawn]]
		under.a = theme.get_constant(&"fill_alpha", LINE_CHART) / 1000.0
		theme.set_color(&"fill", drawn, under)
	# a bracket: its rounds across, each round's ties spread down its column so a later tie sits between the two that feed it, and a tie on a ground of its own
	theme.set_type_variation(BRACKET, &"Row")
	theme.set_type_variation(BRACKET_ROUND, &"Column")
	theme.set_constant(&"justify", BRACKET_ROUND, 4)
	for ground: StringName in [TIE, GRAPH_PANEL]:
		theme.set_type_variation(ground, &"Surface")
	# every kind of words, a Label sized by its placeholder, in its ink
	for kind: StringName in KINDS:
		theme.set_type_variation(kind, &"Label")
		theme.set_font_size(&"font_size", kind, theme.get_constant(KINDS[kind][0], KPI_CARD))
		theme.set_color(&"font_color", kind, palette[KINDS[kind][1]])
	theme.set_type_variation(KPI_CARD, &"Pressable")
	theme.set_type_variation(PIN, &"Pressable")
	theme.set_type_variation(BAR, &"Pressable")
	# each state of a card, a pin and a bar: its ground, padded, a current bar ruled down its side and a current pin ringed
	for state: StringName in GROUNDS:
		theme.set_stylebox(state, KPI_CARD, _box(palette, GROUNDS[state], pad, 0, false))
		theme.set_stylebox(state, PIN, _box(palette, GROUNDS[state], pad / 4.0, rule if state == &"current" else 0, false))
		theme.set_stylebox(state, BAR, _box(palette, BAR_GROUNDS[state], pad / 4.0, rule if state == &"current" else 0, true))
		# the words' colour in each state, the same for all three
		for pressed: StringName in [KPI_CARD, PIN, BAR]:
			theme.set_color(StringName("font_color_" + state), pressed, palette[INKS[state]])
	# a figure's trend: a trace's ink, and the least height its placeholder gives it
	theme.set_type_variation(TREND, &"Trace")
	# a legend's sample of a line: the chart's inks, and no least height of its own
	theme.set_type_variation(SAMPLE, LINE_CHART)
	theme.set_constant(&"least_height", SAMPLE, 0)
	theme.set_type_variation(BARS, &"Column")
	theme.set_constant(&"gap", BARS, theme.get_constant(&"gap", BAR))
	# a date range: a row that wraps, so a narrow window takes its parts onto more lines rather than past its edge
	theme.set_type_variation(RANGE, &"Row")
	theme.set_constant(&"wrap", RANGE, 1)
	var faded: Color = palette[&"ink"]
	faded.a = theme.get_constant(&"fill_alpha", &"LineChart") / 1000.0
	# the drawn parts: a bar's track and the map, each in the ink, edged and compared in the soft ink, filled in the ink faded
	for drawn: StringName in [TRACK, MAP]:
		theme.set_type_variation(drawn, &"Control")
		theme.set_color(&"line", drawn, palette[&"ink"])
		theme.set_color(&"link", drawn, palette[&"ink_soft"])
		theme.set_color(&"fill", drawn, faded)
		theme.set_color(&"ground", drawn, palette[&"raised"])


## A box in a palette colour - or none, drawing nothing - padded, and ruled
## this thick down its left side alone, or all round.
static func _box(palette: Dictionary, fill: StringName, pad: float, rule: int, left_only: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = fill != &""
	box.bg_color = palette[fill] if fill != &"" else palette[&"ground"]
	box.border_color = palette[&"ink"]
	box.set_border_width_all(0 if left_only else rule)
	box.border_width_left = rule
	box.set_content_margin_all(pad)
	return box
