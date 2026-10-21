extends "describe_shapes.gd"

const PriorityRow := preload("priority_row.gd")

## The descriptions of pieces that answer to the room they are given rather
## than to what they hold: a page that scrolls down, the same parts in the
## first arrangement that fits, as many columns as fit, a slot as wide as
## its widest sample, a held line folding by rank, the first of two pieces
## that fits, a table in frozen panes, a piece capped in the room, pieces
## laid where a plan puts them, and the band of a pop-up's shade round the
## safe rect.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rest of the vocabulary is describe.gd's and describe_shapes.gd's,
## which this extends; describe_values.gd extends this, and the builder
## (ui.gd) extends them all. These stand apart because each is laid out by
## the room it is given, never by all that it holds would like: a page's,
## a slot's and a held line's least never grow with what they show, so one
## wide piece inside cannot widen what holds it - the page, the app or the
## window.


## A page that scrolls down (page_scroll.gd): it asks for no room of its
## own, and lays what it holds at exactly its width, so a piece too wide for
## it is cut inside it and said, never passed up. Each screen's one scroll
## that runs down. Given a bound value naming a piece, it brings that piece
## into view as the name moves, and given one to follow, a press at a time
## moves it, as a scroll does.
func page_scroll(content: Desc, reveal: Bound = null, nudged: Bound = null, style: StringName = &"Scroll") -> Desc:
	return Desc.new(&"page_scroll", {"reveal": reveal, "nudged": nudged, "style": style}, [content])


## The same parts in the first of these arrangements - each a row_of or a
## column_of (describe_shapes.gd), in the order they are preferred - whose
## parts' least sizes fit the room it is given (by_room.gd): {name:
## description}, the arrangements, and the most share of the safe room's
## height an arrangement may need down, none given no limit. Only the
## arrangement ever changes, so state and focus are kept. A row is made one
## of these by its mark, stacks (desc.gd).
func by_room(parts: Dictionary, arrangements: Array, most_tall: float = 0.0) -> Desc:
	return Desc.new(&"by_room", {"names": parts.keys(), "arrangements": arrangements, "most_tall": most_tall}, parts.values())


## As many equal columns of these parts as fit the width this has
## (layout.gd): each at least the look's constant named under Columns, in
## base pixels - none named, the widest part's least - at most `most`, none
## no most. Marked balanced and shares_height where it wants either (desc.gd).
func columns(parts: Array, least: StringName = &"", most: int = 0, style: StringName = &"Columns") -> Desc:
	return Desc.new(&"columns", {"least": least, "most": most, "style": style}, parts)


## A slot holding the room of the widest of these samples in this kind of
## words, whatever what it holds shows now (room_for.gd): a clock, a balance.
func room_for(content: Desc, samples: Array, style: StringName) -> Desc:
	return Desc.new(&"room_for", {"samples": samples, "style": style}, [content])


## A held line of parts in rank order, each {name, part, short, folds},
## taking short forms and folding by rank as the room runs short, and
## writing the folded names to this local (priority_row.gd); the menu press
## shown while a part folds behind it, or none.
func priority_row(parts: Array, folded: Local, menu: Desc = null, style: StringName = &"Row") -> Desc:
	return PriorityRow.described(parts, folded, menu, style)


## The first piece while its least fits the room it is given, else the
## second (while_fits.gd): a list scrolling itself, else drawn whole.
func while_fits(first: Desc, otherwise: Desc) -> Desc:
	return Desc.new(&"while_fits", {}, [first, otherwise])


## A table wider or taller than its room (frozen_panes.gd): the corner
## fixed, the heads following the body across and the labels following it
## down, the body scrolling either way; never a column under its least, no
## column dropped. Options: columns (required), a bound value reading the
## column names in rank order; least_column, a constant under Columns every
## column is at least; samples {column: {"words"}} and words_kind, for
## columns measured by their words; widths, a local set to the columns'
## widths as they move; style, the look holding gap and pad (FrozenPanes);
## nudged, as a scroll's. Marked whole_down, it scrolls across alone (desc.gd).
const FROZEN_PANES_OPTIONS: Array[String] = ["columns", "least_column", "samples", "words_kind", "widths", "style", "nudged"]

func frozen_panes(corner: Desc, heads: Desc, labels: Desc, body: Desc, options: Dictionary) -> Desc:
	Options.checked("a table in frozen panes", options, FROZEN_PANES_OPTIONS)
	return Desc.new(&"frozen_panes", {"columns": options["columns"], "least_column": options.get("least_column", &""), "samples": options.get("samples", {}), "words_kind": options.get("words_kind", &""), "widths": options.get("widths"), "style": options.get("style", &"FrozenPanes"), "nudged": options.get("nudged"), "whole_down": false}, [corner, heads, labels, body])


## One piece in the middle of the room it is given, on each axis at what
## it needs, at the cap or across the whole room - Capped.NEEDS, SPANS or
## FILLS - the cap the room less the margin this look names, at most its
## most_wide and most_tall, and never under the piece's least (capped.gd).
func capped(piece: Desc, look: StringName, across: int, down: int) -> Desc:
	return Desc.new(&"capped", {"look": look, "across": across, "down": down}, [piece])


## A pop-up's shade in this look painted over all of the window outside
## the pop-up's rect (shade_band.gd): the band round the safe rect darkened.
func shade_band(style: StringName) -> Desc:
	return Desc.new(&"shade_band", {"style": style})


## Pieces laid where a plan puts them, at the type sizes it gives them, in
## the room this is given, scrolling with bars and arrows in this look where
## the plan needs more (planned.gd): plan(room, on) -> {"rects", "types",
## "size"}, and "shown" and "ground" where it says them; `least`, a height
## or width of its own it never goes under - a bar's.
func planned(pieces: Array, plan: Callable, look: StringName, least := Vector2.ZERO) -> Desc:
	return Desc.new(&"planned", {"plan": plan, "look": look, "least": least}, pieces)
