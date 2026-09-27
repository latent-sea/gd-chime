extends RefCounted

const Themes := preload("theme.gd")
const PaintedBox := preload("painted_box.gd")
const Flex := preload("components/primitives/flex.gd")

## BUTTONS AND PRESSABLES, as the floor's look draws them until a look says
## otherwise: the pressable itself in every state it passes through, the
## common button, a toggle and a choice's options, the inline options of a
## radio group and of a segmented control, and the rows of presses a recipe
## lays out - the prompt bar, the instruction bar, a collection's controls,
## a disposition's picker.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT PUTS ENTRIES INTO THE THEME IT IS HANDED AND HOLDS NOTHING: theme.gd
## calls dress() first of all the families, because every other family reads
## the pressable's boxes back out of the theme to build its own. Like every
## floor look they are placeholders, from the palette's names; the room
## either side of an inline option's words is undecided and lives in
## theme_placeholders.gd with the rest.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS. Every style a floor recipe names
## is registered here as a variation of its base, so a look that sets
## nothing still lays the recipe out as a row of presses and draws it as a
## pressable; a look changes the values, never whether the style exists. A
## constant is written only where the recipe needs something other than the
## base's - the bar of a field's mark beside its line is centred across,
## the plain row's parts are stretched.
##
## THE CHOSEN LOOK IS THE SAME WHOEVER CHOSE, and never hue alone. An
## option picked through the door wears its chosen style by a bound style
## while it draws normal; one that sets a local wears it too, while it
## draws selected (press_local.gd) - so a chosen style's selected box is its
## normal one, and each carries a bar of ink: a radio's at its start, a
## segment's along its foot.
##
## NO SEGMENT'S BOX IS DRAWN ONTO ITS NEIGHBOUR: joined segments would draw
## each one's shadow over the next, which is one thing drawn over another,
## so stand_apart() reads how far a segment's boxes draw past their sides
## and stands them that far apart (painted_box.gd). A look whose segments
## draw nothing past their sides keeps them joined.

## The common button, and the bar a prompt stands in.
const BUTTON := &"BellButton"
const PROMPT_BAR := &"PromptBar"
## A toggle's two looks: off as any pressable, on marked along its foot.
const TOGGLE_ON := &"ToggleOn"
const TOGGLE_OFF := &"ToggleOff"
## A choice's options: a pressable, and the one whose value is the setting's marked along its foot, as a toggle turned on is.
const CHOICE := &"Choice"
const CHOICE_CHOSEN := &"ChoiceChosen"
## A radio group's options and a segmented control's, joined in their row.
const RADIO := &"Radio"
const RADIO_CHOSEN := &"RadioChosen"
const SEGMENTS := &"Segments"
const SEGMENT := &"Segment"
const SEGMENT_CHOSEN := &"SegmentChosen"
## How thick a chosen option's bar of ink is, as the toggle's is.
const MARK := 6
## The room either side of an inline option's words, read under SEGMENT: a placeholder.
const PAD := &"option_pad"
## The side each chosen option carries its bar on.
const BARS := {RADIO_CHOSEN: SIDE_LEFT, SEGMENT_CHOSEN: SIDE_BOTTOM}
## The rows of presses a recipe lays out, each with the base it varies.
const LINES := {PROMPT_BAR: Themes.ROW, &"InstructionBar": Themes.ROW, &"Controls": Themes.ROW, &"Picker": Themes.ROW, &"Disposition": Themes.COLUMN}
## The rows among them whose parts stand in the middle across the line, so a mark, a field and a press line up.
const CENTRED: Array[StringName] = [&"InstructionBar", &"Controls"]


## Every press's type put into this theme, from this palette.
static func dress(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(Themes.PRESSABLE, &"Control")
	# each state: a flat ground, and the words' colour on it
	for state: StringName in Themes.GROUNDS:
		theme.set_stylebox(state, Themes.PRESSABLE, _flat(palette[Themes.GROUNDS[state]]))
		theme.set_color(StringName("font_color_" + state), Themes.PRESSABLE, palette[Themes.INKS[state]])
	# the focus: a ring in ink just inside the control's edge, so it never reads as the glow spilling out
	var ring := _flat(palette[&"ground"])
	ring.draw_center = false
	ring.border_color = palette[&"ink"]
	ring.set_border_width_all(4)
	theme.set_stylebox(&"focus", Themes.PRESSABLE, ring)
	# the ground it would take what is carried on, and, refusing, a plain ground ringed in the soft ink - the reason itself is in its words
	theme.set_stylebox(&"accepting", Themes.PRESSABLE, _flat(palette[Themes.GROUNDS[&"glowing"]]))
	theme.set_color(&"font_color_accepting", Themes.PRESSABLE, palette[Themes.INKS[&"glowing"]])
	var refusing := _flat(palette[Themes.GROUNDS[&"inert"]])
	refusing.border_color = palette[&"ink_soft"]
	refusing.set_border_width_all(4)
	theme.set_stylebox(&"refusing", Themes.PRESSABLE, refusing)
	theme.set_color(&"font_color_refusing", Themes.PRESSABLE, palette[&"ink_soft"])
	# carried: the ground it left, so where it came from reads as emptied
	theme.set_stylebox(&"lifted", Themes.PRESSABLE, _flat(palette[Themes.GROUNDS[&"inert"]]))
	theme.set_color(&"font_color_lifted", Themes.PRESSABLE, palette[&"ink_soft"])
	# the plain presses: the common button, a toggle turned off and a choice's options, each the pressable unchanged
	for plain: StringName in [BUTTON, TOGGLE_OFF, CHOICE]:
		theme.set_type_variation(plain, Themes.PRESSABLE)
	# the two marked looks: a pressable's grounds with a bar of ink along the foot
	for marked: StringName in [TOGGLE_ON, CHOICE_CHOSEN]:
		theme.set_type_variation(marked, Themes.PRESSABLE)
		# every state, its ground barred along the foot, padded as the pressable is so turning on moves nothing beside it
		for state: StringName in Themes.GROUNDS:
			var turned := _flat(palette[Themes.GROUNDS[state]])
			turned.border_color = palette[&"ink"]
			turned.border_width_bottom = MARK
			turned.content_margin_bottom = 0.0
			theme.set_stylebox(state, marked, turned)
	_options(theme, palette)
	# every row of presses a recipe names: a line of its base, so a look that sets nothing still lays it out
	for line: StringName in LINES:
		theme.set_type_variation(line, LINES[line])
	# the ones whose parts line up across the row rather than stretching down it
	for centred: StringName in CENTRED:
		theme.set_constant(&"align", centred, Flex.CENTER)


## The four inline option looks - a radio's and a segment's, plain and
## chosen - from the floor's own pressable: the chosen two with a bar of
## ink, and each option's words with room of their own, since joined
## segments have no gap between them and their words would run together.
static func _options(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(SEGMENTS, Themes.ROW)
	var pad := float(theme.get_constant(PAD, SEGMENT))
	# every option, on every state's ground, the chosen two barred on their own side
	for option: StringName in [RADIO, SEGMENT, RADIO_CHOSEN, SEGMENT_CHOSEN]:
		theme.set_type_variation(option, Themes.PRESSABLE)
		for state: StringName in Themes.GROUNDS:
			var marked := _flat(palette[Themes.GROUNDS[state]])
			marked.set_content_margin_all(pad)
			marked.border_color = palette[&"ink"]
			marked.border_width_left = MARK if option == RADIO_CHOSEN else 0
			marked.border_width_bottom = MARK if option == SEGMENT_CHOSEN else 0
			theme.set_stylebox(state, option, marked)
	# the chosen two drawn selected as they are drawn normal, whoever chose
	for chosen: StringName in BARS:
		theme.set_stylebox(&"selected", chosen, theme.get_stylebox(&"normal", chosen))
		theme.set_color(&"font_color_selected", chosen, palette[Themes.INKS[&"normal"]])
	stand_apart(theme)


## The segments stood as far apart as their boxes draw past their sides, so
## no segment's shadow lies under its neighbour; boxes drawing nothing past
## their sides leave them joined.
static func stand_apart(theme: Theme) -> void:
	var reach := [0.0, 0.0]
	# every box a segment is drawn in, plain or chosen, for the furthest any draws past its left and past its right
	for segment: StringName in [SEGMENT, SEGMENT_CHOSEN]:
		for state: String in theme.get_stylebox_list(segment):
			reach = [maxf(reach[0], PaintedBox.reach_of(theme.get_stylebox(state, segment), SIDE_LEFT)), maxf(reach[1], PaintedBox.reach_of(theme.get_stylebox(state, segment), SIDE_RIGHT))]
	theme.set_constant(&"gap", SEGMENTS, ceili(reach[0] + reach[1]))


## A flat box of one fill.
static func _flat(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	return box
