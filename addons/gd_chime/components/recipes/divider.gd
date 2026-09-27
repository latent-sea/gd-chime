extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Desc := preload("../primitives/desc.gd")
const Themes := preload("../../theme.gd")

## A divider: a rule placed between parts - across a column, or down a row -
## drawn as the look's style says.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## A RECIPE, NOT A PRIMITIVE: it draws nothing of its own. It is a surface
## whose panel is the look's rule - a line, its thickness and the air either
## side of it (theme.gd) - so it needs the room the air gives it along
## the line it sits in, takes the whole width of a column or height of a row
## as any part does, and a look draws it however it likes, or not at all.
##
## It must never stand for a gap: the air between parts is the line's gap,
## and a divider is placed only where a rule is meant to be seen.


## A rule across a column: between the parts above it and below.
static func across(ui: Ui, style: StringName = Themes.DIVIDER_ACROSS) -> Desc:
	return ui.surface(style)


## A rule down a row: between the parts before it and after.
static func down(ui: Ui, style: StringName = Themes.DIVIDER_DOWN) -> Desc:
	return ui.surface(style)
