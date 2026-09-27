extends RefCounted

const Themes := preload("theme.gd")
const Flex := preload("components/primitives/flex.gd")

## FIELDS, as the floor's look draws them until a look says otherwise:
## everything a reader types into or sets a value with - the typed line
## itself, a text area, code, an amount, a slider, a stepper, a combo, a
## type-ahead, a key binding, a chip and the filters built from them - and a
## form of many steps: a question and the message beside it, a section asked
## while an answer holds, the steps along the top, the summary of what needs
## attention, a step of the review, a date field and the calendar's days.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## IT PUTS ENTRIES INTO THE THEME IT IS HANDED AND HOLDS NOTHING: theme.gd
## calls dress() as it builds itself, so every look merged over the floor's
## has these to fall back on, and a look sets its own over any of them. They
## are placeholders from the palette's names; the numbers they need are
## undecided and live in theme_placeholders.gd - the slider's handle, track
## and gap, a text area's least and most lines, the gaps a form asks for.
##
## A RECIPE OWNS ITS STRUCTURAL VARIANTS: every line a field's recipe names
## is registered here as a variation of its base, so a look that sets
## nothing lays it out; the lines where a mark, a line and a press must read
## as one thing are centred across, which a plain row does not do.
##
## NOTHING IS TOLD BY HUE ALONE. A message is in the accent AND begins with
## its mark (MESSAGE_MARK, said by the recipe); a step needing attention has
## the accent's bar AND its count in its words; a step done, a bar of ink and
## its mark; the day chosen, a bar of ink as a chosen option has; today, a
## ring; a day of another month, the soft ink.

## The slider's style: not "Slider", which the engine's own Slider holds, and a type the engine has cannot be made a variation.
const SLIDER := &"ValueSlider"
const STEPPER := &"Stepper"
const COMBO := &"Combo"
## How much of the window's height a long combo's sheet takes, in thousandths, read under COMBO: a placeholder.
const TALL := &"sheet_tall"
## A typed line, whatever it is for: an amount, a name, a type-ahead - one
## style, a variation of the engine's LineEdit, so a look dresses them all.
const FIELD := &"Field"
## Words typed over more than one line, and code among them - words set in a fixed width.
const TEXT_AREA := &"TextArea"
const CODE := &"Code"
## The fixed-width families code is set in, the first the machine has, until a look names its own.
const FIXED_WIDTH: Array[String] = ["Consolas", "Cascadia Mono", "Menlo", "DejaVu Sans Mono", "Courier New", "monospace"]
## The lines a field stands in with its mark, its label or its press.
const AMOUNT_FIELD := &"AmountField"
const TEXT_FIELD_ROW := &"TextFieldRow"
const SETTING_ROW := &"SettingRow"
const DATE_FIELD := &"DateField"
## A type-ahead's column and one of its options; a key binding, which is a press that listens.
const TYPE_AHEAD := &"TypeAhead"
const TYPE_AHEAD_OPTION := &"TypeAheadOption"
const BINDING := &"Binding"
## A chip, the line chips flow along, and the filters built of them.
const CHIP := &"Chip"
const CHIPS := &"Chips"
const FILTER_SET := &"FilterSet"
const BUILDER := &"Builder"
## The sheet a step's page stands on - nothing on the floor's look, paper where a look is paper - and the step's heading on it.
const PAGE := &"FormPage"
const HEADING := &"FormHeading"
const QUESTION := &"Question"
const MESSAGE := &"Message"
const SECTION := &"FormSection"
const STEPS := &"Steps"
const STEP := &"Step"
const STEP_DONE := &"StepDone"
const STEP_NEEDS := &"StepNeeds"
const SUMMARY := &"ErrorSummary"
const REVIEW_STEP := &"ReviewStep"
const WEEK := &"CalendarWeek"
const DAY := &"CalendarDay"
const DAY_CHOSEN := &"CalendarDayChosen"
const DAY_TODAY := &"CalendarDayToday"
const DAY_OUTSIDE := &"CalendarDayOutside"
## How thick a bar or a ring of the form's looks is, in base pixels, as the chosen option's is.
const MARK := 6
## The mark a message begins with, so it is never told by its colour alone.
const MESSAGE_MARK := "! "
## Every line a field's recipe names, with the base it varies.
const LINES := {AMOUNT_FIELD: Themes.ROW, SETTING_ROW: Themes.ROW, DATE_FIELD: Themes.ROW, STEPPER: Themes.ROW, WEEK: Themes.ROW, BUILDER: Themes.ROW, TEXT_FIELD_ROW: Themes.COLUMN, QUESTION: Themes.COLUMN, TYPE_AHEAD: Themes.COLUMN, FILTER_SET: Themes.COLUMN, CHIPS: Themes.TILES, STEPS: Themes.TILES}
## The lines whose parts read as one thing across, so a mark, a line and a press line up rather than stretching.
const CENTRED: Array[StringName] = [AMOUNT_FIELD, SETTING_ROW, DATE_FIELD, STEPPER]


static func dress(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(FIELD, &"LineEdit")
	theme.set_type_variation(COMBO, Themes.PRESSABLE)
	# a press that listens for a key, and one option of a type-ahead: presses
	for press: StringName in [BINDING, TYPE_AHEAD_OPTION, CHIP]:
		theme.set_type_variation(press, Themes.PRESSABLE)
	# every line a field stands in: its base, so a look that sets nothing lays it out
	for line: StringName in LINES:
		theme.set_type_variation(line, LINES[line])
	# the ones whose parts line up across the line
	for centred: StringName in CENTRED:
		theme.set_constant(&"align", centred, Flex.CENTER)
	# the slider: a pressable's grounds and focus, and the three boxes of its own it draws in its band
	theme.set_type_variation(SLIDER, Themes.PRESSABLE)
	theme.set_stylebox(&"track", SLIDER, _flat(palette[&"ground"]))
	theme.set_stylebox(&"fill", SLIDER, _flat(palette[&"accent"]))
	theme.set_stylebox(&"handle", SLIDER, _flat(palette[&"ink"]))
	_typed(theme, palette)
	_form(theme, palette)


## A text area and code: the raised ground, padded, ringed in the ink while
## it has the focus, and code in the machine's own fixed width until a look
## names one.
static func _typed(theme: Theme, palette: Dictionary) -> void:
	theme.set_type_variation(TEXT_AREA, &"TextEdit")
	var ground := _flat(palette[&"raised"])
	ground.set_content_margin_all(8.0)
	theme.set_stylebox(&"normal", TEXT_AREA, ground)
	theme.set_stylebox(&"read_only", TEXT_AREA, ground)
	var ring := _flat(palette[&"ground"])
	ring.draw_center = false
	ring.border_color = palette[&"ink"]
	ring.set_border_width_all(4)
	theme.set_stylebox(&"focus", TEXT_AREA, ring)
	# the words and the caret in the ink, a selection on the lit ground
	for ink: StringName in [&"font_color", &"caret_color"]:
		theme.set_color(ink, TEXT_AREA, palette[&"ink"])
	theme.set_color(&"font_readonly_color", TEXT_AREA, palette[&"ink_soft"])
	theme.set_color(&"selection_color", TEXT_AREA, palette[&"lit"])
	# code: a text area whose words stand in a fixed width, no taller at least than the placeholder's lines
	theme.set_type_variation(CODE, TEXT_AREA)
	var fixed := SystemFont.new()
	fixed.font_names = PackedStringArray(FIXED_WIDTH)
	theme.set_font(&"font", CODE, fixed)
	theme.set_constant(&"most_lines", CODE, 3)


## A form of many steps: its page and heading, a question and its message,
## a section asked while an answer holds, each step's three looks, the
## summary, a step of the review, and the calendar's days.
static func _form(theme: Theme, palette: Dictionary) -> void:
	# a step's page: nothing of its own on the floor's look; its heading, the size of words a step is named in
	theme.set_type_variation(PAGE, Themes.SURFACE)
	theme.set_stylebox(&"panel", PAGE, StyleBoxEmpty.new())
	theme.set_type_variation(HEADING, Themes.WORDS)
	# a message: in the accent, the size of a reason
	theme.set_type_variation(MESSAGE, &"Label")
	theme.set_font_size(&"font_size", MESSAGE, Themes.SIZES[Themes.REASON])
	theme.set_color(&"font_color", MESSAGE, palette[&"accent"])
	# a section asked while an answer holds: the raised ground with a bar of the soft ink down its start, so it reads as belonging to what opened it
	theme.set_type_variation(SECTION, Themes.SURFACE)
	theme.set_stylebox(&"panel", SECTION, _barred(palette[&"raised"], palette[&"ink_soft"], SIDE_LEFT, float(theme.get_constant(&"pad", SUMMARY))))
	# each step's three looks: open as any pressable, done barred in ink, needing attention barred in the accent
	for step: Array in [[STEP, &""], [STEP_DONE, &"ink"], [STEP_NEEDS, &"accent"]]:
		theme.set_type_variation(step[0], Themes.PRESSABLE)
		# every state a pressable is drawn in, on that state's ground, barred along its foot where the look says
		for state: StringName in Themes.GROUNDS:
			theme.set_stylebox(state, step[0], _barred(palette[Themes.GROUNDS[state]], palette[step[1]] if step[1] != &"" else palette[Themes.GROUNDS[state]], SIDE_BOTTOM, 0.0))
		theme.set_stylebox(&"current", step[0], _barred(palette[&"lit"], palette[&"accent"], SIDE_BOTTOM, 0.0))
		theme.set_color(&"font_color_current", step[0], palette[&"ink"])
	# the summary of what needs attention, and a step of the review: the raised ground, the summary with the accent's bar down its start
	theme.set_type_variation(SUMMARY, Themes.SURFACE)
	theme.set_stylebox(&"panel", SUMMARY, _barred(palette[&"raised"], palette[&"accent"], SIDE_LEFT, float(theme.get_constant(&"pad", SUMMARY))))
	theme.set_type_variation(REVIEW_STEP, Themes.SURFACE)
	theme.set_stylebox(&"panel", REVIEW_STEP, _barred(palette[&"raised"], palette[&"raised"], SIDE_LEFT, float(theme.get_constant(&"pad", SUMMARY))))
	# a day: a pressable; chosen, barred in ink; today, ringed in the accent; of another month, in the soft ink
	for day: StringName in [DAY, DAY_CHOSEN, DAY_TODAY, DAY_OUTSIDE]:
		theme.set_type_variation(day, Themes.PRESSABLE)
	# every state a day is drawn in, the chosen day's and today's boxes on that state's ground
	for state: StringName in Themes.GROUNDS:
		theme.set_stylebox(state, DAY_CHOSEN, _barred(palette[Themes.GROUNDS[state]], palette[&"ink"], SIDE_BOTTOM, 0.0))
		var ringed := _barred(palette[Themes.GROUNDS[state]], palette[&"accent"], SIDE_BOTTOM, 0.0)
		ringed.set_border_width_all(MARK)
		ringed.set_content_margin_all(MARK)
		theme.set_stylebox(state, DAY_TODAY, ringed)
	theme.set_color(&"font_color_normal", DAY_OUTSIDE, palette[&"ink_soft"])


## A flat box of one fill.
static func _flat(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	return box


## A flat box of one fill with a bar of another colour along one side,
## padded this much every way - and past the bar on its side, so nothing
## held is drawn over it.
static func _barred(fill: Color, bar: Color, side: Side, pad: float) -> StyleBoxFlat:
	var box := _flat(fill)
	box.border_color = bar
	box.set_border_width(side, MARK)
	box.set_content_margin_all(pad)
	box.set_content_margin(side, pad + MARK)
	return box
