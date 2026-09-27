extends "gd_chime_recipes.gd"

## The facade's second lazy list: the parts of the vocabulary, the look and the
## floor that no application names where GDScript demands a constant, each
## fetched the first time its name is read.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Read through the one name, as `GdChime.Motion`, `GdChime.Formats.written_number(...)`,
## `GdChime.Question.YES_NO`: a static var is inherited, so where in the
## facade's chain a name is written is not something a call site knows.
##
## THE DIVIDING LINE, and the only one: a name an application uses as a TYPE -
## a variable's, an argument's, a return's, an `is`, an element's - or reads
## inside a `const` of its own, has to be a constant, because the parser
## resolves both before anything runs. Those names are in gd_chime.gd. Every
## other name is here or in gd_chime_recipes.gd. So `GdChime.Bound` is eager
## because a demo writes `var x: GdChime.Bound`, and `GdChime.Motion` is lazy
## because nothing writes `var x: GdChime.Motion`.
## Moving a name across the line is a one-line change in each file.
##
## Several of these load at start anyway, and would even if this list were
## empty - application.gd names the chimes, the driver, the motion clock and
## the register by their own paths, as a file of the floor should. They are
## here because it is not the facade's business to know which, and a name that
## is free either way costs nothing to write lazily.
##
## A name here is a PROMISE (CONSTITUTION.md): removing one or pointing it
## somewhere else is a break, written in the CHANGELOG. Adding one is not.
## IT IS A LIST AND NOTHING ELSE: no function, no value, never made.

## --- the vocabulary: what describes, beside the builder ---
static var Draggable: GDScript:
	get: return _at("components/primitives/draggable.gd")
static var Grip: GDScript:
	get: return _at("components/primitives/grip.gd")
static var Layout: GDScript:
	get: return _at("components/primitives/layout.gd")
static var MenuTarget: GDScript:
	get: return _at("components/primitives/menu_target.gd")
static var Places: GDScript:
	get: return _at("components/primitives/describe_places.gd")
static var SimulatedSight: GDScript:
	get: return _at("components/primitives/simulated_sight.gd")
static var Text: GDScript:
	get: return _at("components/primitives/text.gd")
static var Transition: GDScript:
	get: return _at("components/primitives/transition.gd")

## --- the look: the Theme's families of types, and what paints one ---
static var Charts: GDScript:
	get: return _at("theme_charts.gd")
static var Collections: GDScript:
	get: return _at("theme_collections.gd")
static var Feedback: GDScript:
	get: return _at("theme_feedback.gd")
static var Fields: GDScript:
	get: return _at("theme_fields.gd")
static var Look: GDScript:
	get: return _at("look.gd")
static var MotionTokens: GDScript:
	get: return _at("motion_tokens.gd")
static var Navigation: GDScript:
	get: return _at("theme_navigation.gd")
static var Paint: GDScript:
	get: return _at("paint.gd")
static var PaintedBox: GDScript:
	get: return _at("painted_box.gd")
static var Pressables: GDScript:
	get: return _at("theme_pressables.gd")
static var Tables: GDScript:
	get: return _at("theme_tables.gd")

## --- the floor: the door, the chimes, the driver, and the models an application is made of ---
static var Belfry: GDScript:
	get: return _at("belfry.gd")
static var Carried: GDScript:
	get: return _at("carried.gd")
static var Catalogues: GDScript:
	get: return _at("catalogues.gd")
static var Commands: GDScript:
	get: return _at("commands.gd")
static var Console: GDScript:
	get: return _at("console.gd")
static var Dates: GDScript:
	get: return _at("dates.gd")
static var DebugLog: GDScript:
	get: return _at("debug_log.gd")
static var DevCommands: GDScript:
	get: return _at("dev_commands.gd")
static var EditingCell: GDScript:
	get: return _at("editing_cell.gd")
static var FormActions: GDScript:
	get: return _at("form_actions.gd")
static var Formats: GDScript:
	get: return _at("formats.gd")
static var Guide: GDScript:
	get: return _at("guide.gd")
static var Inputs: GDScript:
	get: return _at("input_map.gd")
static var Language: GDScript:
	get: return _at("language.gd")
static var LongList: GDScript:
	get: return _at("long_list.gd")
static var Motion: GDScript:
	get: return _at("motion.gd")
static var Prompts: GDScript:
	get: return _at("prompts.gd")
static var Question: GDScript:
	get: return _at("question.gd")
static var Reads: GDScript:
	get: return _at("reads.gd")
static var Reminders: GDScript:
	get: return _at("reminders.gd")
static var RowEdits: GDScript:
	get: return _at("row_edits.gd")
static var RowFilters: GDScript:
	get: return _at("row_filters.gd")
static var RowQuery: GDScript:
	get: return _at("row_query.gd")
static var RowSelection: GDScript:
	get: return _at("row_selection.gd")
static var SaveShape: GDScript:
	get: return _at("save_shape.gd")
static var Shape: GDScript:
	get: return _at("shape.gd")
static var Sounds: GDScript:
	get: return _at("sounds.gd")
static var SoundBus: GDScript:
	get: return _at("sound_bus.gd")
static var Stretch: GDScript:
	get: return _at("stretch.gd")
static var TableColumns: GDScript:
	get: return _at("table_columns.gd")
static var Taken: GDScript:
	get: return _at("taken.gd")
static var Thresholds: GDScript:
	get: return _at("thresholds.gd")
static var Token: GDScript:
	get: return _at("token.gd")
static var Touch: GDScript:
	get: return _at("touch.gd")
static var ViewBehind: GDScript:
	get: return _at("view_behind.gd")
