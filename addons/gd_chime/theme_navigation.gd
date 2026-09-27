extends RefCounted

const Themes := preload("theme.gd")
const Flex := preload("components/primitives/flex.gd")

## NAVIGATION, as the floor's look draws it until a look says otherwise:
## everything that takes the reader somewhere or divides where they are -
## tabs and their panel, a document's flap, a section and its heading, a
## link in running words, an inline way out and a step back, the bar at a
## phone's foot and the rail at a wider window's side, and the panes,
## grips and foot an application's shell is framed by.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## theme.gd calls dress() once, with the palette it was given; this puts its
## types into that theme and holds nothing, and a look dresses any of them
## again after it. It names a colour only by the palette's name for it. The
## grip's numbers - how thick it is and how far a key steps it - are
## PLACEHOLDERS nobody has decided, and theme_placeholders.gd holds them.
##
## A TAB IS A FLAP ON THE PANEL IT REVEALS: the flaps sit bottom-aligned on
## a strip with no gap over the panel, and the current one stands taller in
## the panel's own fill, merging into it. A document's flap is joined to its
## closing mark and stands on the same baseline.
##
## NOTHING HERE SAYS A THING BY HUE ALONE. The destination the reader is at
## is drawn current - the lit ground edged in the accent, thick - as well as
## inked; a link where it can be pressed carries a rule under its words.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS: every line navigation's recipes
## name is registered here as a variation of its base, so a look that sets
## nothing lays it out; the tabs' strip and set keep the packing a flap on a
## panel needs.

## Tabs: a flap, the flaps' row, the panel the current flap merges into, the set, and a document's flap.
const TAB := &"Tab"
const TAB_STRIP := &"TabStrip"
const TAB_PANEL := &"TabPanel"
const TAB_SET := &"TabSet"
const DOCUMENT_FLAP := &"DocumentFlap"
## A section's heading: a pressable that draws open - its selected - as it draws shut, the mark in its words saying which. Its body, and the column of them.
const SECTION_HEADING := &"SectionHeading"
const SECTION := &"Section"
const SECTIONS := &"Sections"
## An entity named in running words: a pressable drawn as words with a rule under them.
const LINK := &"Link"
## A way out said in running words, and a step to the piece before or after.
const NAV_INLINE := &"NavInline"
const NAV_PLAY := &"NavPlay"
## The navigation: its line at a phone's foot, the same line down a wider window's side, a destination in it, and the frame the two share.
const NAV_BAR := &"NavBar"
const NAV_RAIL := &"NavRail"
const NAV_ITEM := &"NavItem"
const NAV_FRAME := &"NavFrame"
## A phone's screen: its ground, with the air kept between what it holds and the glass's edge.
const SCREEN := &"PhoneScreen"
## The shell: the grip the reader resizes a pane or a column by, a pane, its column, what the application says about itself in the foot, and the foot itself.
const GRIP := &"Grip"
const PANE := &"Pane"
const PANE_COLUMN := &"PaneColumn"
const STATUS := &"ShellStatus"
const SHELL_FOOT := &"ShellFoot"
## A link's ground and words in each state, as palette names; a state with no ground draws its words alone.
const LINK_GROUNDS := {&"hover": &"lit", &"glowing": &"accent"}
const LINK_INKS := {&"normal": &"accent", &"hover": &"ink", &"inert": &"ink_soft", &"glowing": &"ground", &"current": &"ink"}
## The states a link is ruled under in: where it can be pressed and is not lit.
const RULED: Array[StringName] = [&"normal"]
## Every line navigation's recipes name, with the base it varies.
const LINES := {TAB_STRIP: Themes.ROW, TAB_SET: Themes.COLUMN, DOCUMENT_FLAP: Themes.ROW, SECTIONS: Themes.COLUMN, SECTION: Themes.COLUMN, NAV_BAR: Themes.ROW, NAV_RAIL: Themes.COLUMN, NAV_FRAME: Themes.ROW, PANE_COLUMN: Themes.COLUMN}
## Every press navigation's recipes name, each drawn as a pressable until a look says otherwise.
const PRESSES: Array[StringName] = [TAB, GRIP, NAV_ITEM, NAV_INLINE, NAV_PLAY, SECTION_HEADING, LINK]


static func dress(theme: Theme, palette: Dictionary) -> void:
	# every line: its base, so a look that sets nothing lays it out
	for line: StringName in LINES:
		theme.set_type_variation(line, LINES[line])
	# every press: the pressable, until a look dresses it
	for press: StringName in PRESSES:
		theme.set_type_variation(press, Themes.PRESSABLE)
	_tabs(theme, palette)
	_sections(theme, palette)
	_link(theme, palette)
	_phone(theme, palette)
	_shell(theme, palette)


## Tabs: flaps with their top corners rounded, bottom-aligned on a strip
## with no gap over the panel; the current flap in the panel's fill,
## taller, merging into it; a document's flap joined to its closing mark.
static func _tabs(theme: Theme, palette: Dictionary) -> void:
	# every state a flap is drawn in, its box
	for state: StringName in Themes.GROUNDS:
		theme.set_stylebox(state, TAB, _flap(palette[Themes.GROUNDS[state]], 6.0))
	theme.set_stylebox(&"current", TAB, _flap(palette[&"lit"], 12.0))
	theme.set_color(&"font_color_current", TAB, palette[&"ink"])
	theme.set_constant(&"gap", TAB_STRIP, 2)
	theme.set_constant(&"align", TAB_STRIP, Flex.END)
	theme.set_constant(&"gap", TAB_SET, 0)
	theme.set_type_variation(TAB_PANEL, Themes.SURFACE)
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = palette[&"lit"]
	sheet.set_content_margin_all(8.0)
	theme.set_stylebox(&"panel", TAB_PANEL, sheet)
	theme.set_constant(&"gap", DOCUMENT_FLAP, 0)
	theme.set_constant(&"align", DOCUMENT_FLAP, Flex.END)


## A section's heading, which draws open as it draws shut - the mark in its
## words says which - and the shell's foot, which stands on a ground of its
## own so the frame reads apart from the page.
static func _sections(theme: Theme, palette: Dictionary) -> void:
	theme.set_stylebox(&"selected", SECTION_HEADING, theme.get_stylebox(&"normal", Themes.PRESSABLE))
	theme.set_color(&"font_color_selected", SECTION_HEADING, palette[Themes.INKS[&"normal"]])
	theme.set_type_variation(SHELL_FOOT, Themes.SURFACE)


## A link: a ground where it has one, the rule under its words where it can
## be pressed and is not lit, and its words' colour.
static func _link(theme: Theme, palette: Dictionary) -> void:
	var rule := theme.get_constant(&"rule", &"Divider")
	var air := theme.get_constant(&"air", &"Divider")
	# each state of a link: its box and its ink
	for state: StringName in LINK_INKS:
		var box := StyleBoxFlat.new()
		box.draw_center = LINK_GROUNDS.has(state)
		box.bg_color = palette[LINK_GROUNDS.get(state, &"ground")]
		box.border_color = palette[&"ink_soft"]
		box.border_width_bottom = rule if RULED.has(state) else 0
		box.set_content_margin_all(float(air) / 2.0)
		theme.set_stylebox(state, LINK, box)
		theme.set_color(StringName("font_color_" + state), LINK, palette[LINK_INKS[state]])


## A phone's navigation: destinations abutting at the foot and sharing the
## width, the same line down a wider window's side, and the screen's ground.
static func _phone(theme: Theme, palette: Dictionary) -> void:
	theme.set_constant(&"gap", NAV_BAR, 0)
	theme.set_constant(&"gap", NAV_RAIL, 8)
	theme.set_constant(&"gap", NAV_FRAME, 0)
	var states := {&"normal": _padded(palette[&"raised"]), &"hover": _padded(palette[&"lit"]), &"inert": _padded(palette[&"raised"]), &"glowing": _padded(palette[&"accent"]), &"current": _padded(palette[&"lit"], palette[&"accent"])}
	var inks := {&"normal": &"ink_soft", &"hover": &"ink", &"inert": &"ink_soft", &"glowing": &"ground", &"current": &"ink"}
	# every state a destination is drawn in: its box and its words' ink
	for state: StringName in states:
		theme.set_stylebox(state, NAV_ITEM, states[state])
		theme.set_color(StringName("font_color_" + state), NAV_ITEM, palette[inks[state]])
	theme.set_type_variation(SCREEN, Themes.SURFACE)
	theme.set_stylebox(&"panel", SCREEN, _padded(palette[&"ground"]))


## The shell: a grip whose rest is a quiet rule and whose hold, hover and
## focus are the accent; a pane on the raised ground; and what the
## application says about itself in the foot, in a reason's words.
static func _shell(theme: Theme, palette: Dictionary) -> void:
	# every state the pressable draws, the grip's own box for it
	for state: StringName in Themes.GROUNDS:
		var quiet: bool = state == &"normal" or state == &"inert"
		var bar := StyleBoxFlat.new()
		bar.bg_color = palette[&"lit"] if quiet else palette[&"accent"]
		theme.set_stylebox(state, GRIP, bar)
	theme.set_type_variation(PANE, Themes.SURFACE)
	var ground := StyleBoxFlat.new()
	ground.bg_color = palette[&"raised"]
	ground.set_content_margin_all(8.0)
	theme.set_stylebox(&"panel", PANE, ground)
	theme.set_constant(&"gap", PANE_COLUMN, 6)
	theme.set_type_variation(STATUS, Themes.REASON)


## A flap: a box rounded at its top corners alone, padded this much above
## its words - a tab's shape, whatever fills it.
static func _flap(fill: Color, pad_top: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.corner_radius_top_left = 8
	box.corner_radius_top_right = 8
	box.set_content_margin_all(6.0)
	box.content_margin_top = pad_top
	return box


## A flat box of one fill, padded the floor's way, edged thick in a colour if given one.
static func _padded(fill: Color, edge: Variant = null) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_content_margin_all(12.0)
	if edge != null:
		box.border_color = edge
		box.set_border_width_all(6)
	return box
