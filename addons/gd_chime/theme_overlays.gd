extends RefCounted

const Themes := preload("theme.gd")
const Flex := preload("components/primitives/flex.gd")

## OVERLAYS, as the floor's look draws them until a look says otherwise:
## the shade everything that stands over the screen stands on, the sheet
## itself - which a confirmation, a choice's options, a context menu, a
## drill and a moment all wear - a drawer at the window's edge, a quick
## view, a context menu's items and the command palette's sheet and entries.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## It holds nothing and draws nothing: theme.gd calls dress() as it is
## built, over the palette it was given, and a look dresses any of these
## again after it. It names a colour only by the palette's name for it. Its
## numbers are PLACEHOLDERS nobody has decided, and theme_placeholders.gd
## holds them with the rest: a drawer's shares of the window, a quick view's
## and a drill's.
##
## THE SHADE IS A PRESS: it closes what stands over it (sheet.gd), so it is
## dressed as a pressable in every state and takes no focus ring - it never
## takes the focus - and as a ground too, which a moment stands on.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS: every line and every ground an
## overlay's recipe names is registered here as a variation of its base, so
## a look that sets nothing stands the sheet in the middle of the shade and
## draws it as a surface.

## The shade every sheet stands on, the sheet itself, and the line it stands in, centred both ways.
const SHADE := &"Shade"
const SHEET := &"Confirm"
const ASKED := &"Asked"
## What a moment stands on, and how wide and tall a drill's sheet is, in thousandths of the window.
const MOMENT := &"Moment"
const DRILL := &"DrillDown"
## A drawer's sheet, its head, its column, the press closing it, its foot and the line against the shade (drawer.gd).
const DRAWER := &"Drawer"
const DRAWER_HEAD := &"DrawerHead"
const DRAWER_COLUMN := &"DrawerColumn"
const DRAWER_CLOSE := &"DrawerClose"
const DRAWER_FOOT := &"DrawerFoot"
const DRAWER_LINE := &"DrawerLine"
## A quick view's sheet, its steps and the row they stand in (quick_view.gd).
const QUICK_VIEW := &"QuickView"
const QUICK_VIEW_STEP := &"QuickViewStep"
const QUICK_VIEW_BODY := &"QuickViewBody"
## A context menu's item, and the command palette's sheet and its entries.
const MENU_ITEM := &"MenuItem"
const PALETTE := &"Palette"
const PALETTE_ENTRY := &"PaletteEntry"
## Every state a press is drawn in.
const STATES: Array[StringName] = [&"normal", &"hover", &"inert", &"glowing", &"selected", &"current"]
## Every line an overlay's recipe names, with the base it varies.
const LINES := {ASKED: Themes.ROW, DRAWER_HEAD: Themes.ROW, DRAWER_COLUMN: Themes.COLUMN, DRAWER_LINE: Themes.ROW, DRAWER_FOOT: Themes.ROW, QUICK_VIEW_BODY: Themes.ROW}


static func dress(theme: Theme, palette: Dictionary) -> void:
	# every line an overlay stands in: its base, so a look that sets nothing lays it out
	for line: StringName in LINES:
		theme.set_type_variation(line, LINES[line])
	# the sheet against the shade beside it, and a bottom sheet against the shade either side: no gap between them
	theme.set_constant(&"gap", DRAWER_LINE, 0)
	theme.set_constant(&"gap", DRAWER_FOOT, 0)
	# what is asked stands in the middle of the shade, both ways
	theme.set_constant(&"justify", ASKED, Flex.CENTER)
	theme.set_constant(&"align", ASKED, Flex.CENTER)
	# its head: the title and the close press on one line, centred across it
	theme.set_constant(&"align", DRAWER_HEAD, Flex.CENTER)
	# the presses an overlay carries: a pressable until a look draws them otherwise
	for press: StringName in [DRAWER_CLOSE, QUICK_VIEW_STEP]:
		theme.set_type_variation(press, Themes.PRESSABLE)
	# the sheet: the raised ground, padded, which the drawer, a question, a context menu, a drill, a moment and a quick view all stand on
	var sheet := StyleBoxFlat.new()
	sheet.bg_color = palette[&"raised"]
	sheet.set_content_margin_all(16.0)
	for ground: StringName in [DRAWER, SHEET, QUICK_VIEW, MOMENT]:
		theme.set_type_variation(ground, Themes.SURFACE)
		theme.set_stylebox(&"panel", ground, sheet)
	# the shade: a press drawn as the shade in every state, with no ring, since it never takes the focus - and as a ground, a moment's
	theme.set_type_variation(SHADE, Themes.PRESSABLE)
	var shade := StyleBoxFlat.new()
	shade.bg_color = palette[&"shade"]
	# every state, the same shade
	for state: StringName in STATES + [&"panel"]:
		theme.set_stylebox(state, SHADE, shade)
	theme.set_stylebox(&"focus", SHADE, StyleBoxEmpty.new())
	_menus(theme, palette)


## A context menu's items and the command palette: the palette a sheet
## edged in the soft ink, and an item of either a pressable flat at rest,
## so a list of them reads as a list.
static func _menus(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(PALETTE, Themes.SURFACE)
	var sheet := _flat(palette[&"raised"], 6.0)
	sheet.border_color = palette[&"ink_soft"]
	sheet.set_border_width_all(2)
	sheet.set_content_margin_all(16.0)
	theme.set_stylebox(&"panel", PALETTE, sheet)
	# an item of a context menu or a palette: lit under the pointer and the focus, the accent while chosen
	for item: StringName in [MENU_ITEM, PALETTE_ENTRY]:
		theme.set_type_variation(item, Themes.PRESSABLE)
		# every state, its ground and the ink that goes with it: the raised ground at rest, so nothing marks out an item nobody is on
		for state: StringName in Themes.GROUNDS:
			var quiet: bool = state == &"normal" or state == &"inert"
			theme.set_stylebox(state, item, _flat(palette[&"raised"] if quiet else palette[Themes.GROUNDS[state]], 8.0))
			# a ground set here without an ink leaves the words the look's pressable ink - white, where its presses are white on a colour - on this pale one (faint_words.gd)
			theme.set_color(StringName("font_color_" + state), item, palette[&"ink_soft" if state == &"inert" else &"ink"] if quiet else palette[&"ground"])


## A flat box of one fill, padded this much every way.
static func _flat(fill: Color, pad: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_content_margin_all(pad)
	return box
