extends RefCounted

const Ui := preload("../primitives/ui.gd")
const Options := preload("../primitives/options.gd")
const Desc := preload("../primitives/desc.gd")
const Bound := preload("../primitives/bound.gd")
const FormatMarks := preload("format_marks.gd")
const Phrase := preload("../../phrase.gd")

## A table: many items of one set, a line each, read down a column at a time
## - the columns named overhead, and every heading a control that sorts by
## it. Cells hold values, not cards: this is the shape for comparing.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## SORTING IS THE MODEL'S. A heading pressed is one action with the column
## in its payload; the model sets or turns its order, sorts its own rows and
## rings, and the rows read again - this never sorts, and never remembers
## which column it was by. Which column and which way is a bound value as
## well, {column, ascending}, and the sorted heading says the way in a WORD
## MARK, so it reads where a colour does not.
##
## A column is {name, words, share} and, at most, a cell of its own and a
## format. The shares are what the heading and the cells are grown by, the
## same shares from no width at all, so a heading always stands over its
## column however long its words, which go to the text in English, the
## way's mark beside them as it is. The lines are kept by key, so a re-sort
## moves the lines already built rather than building them again. Given a
## long list, the lines are its slots instead: as many as fit, rebound as it
## scrolls, and the set is never held whole.
##
## A FORMAT dresses a cell by its value: a mark on the words, the kind they
## are in, and the ground they sit on - so a dressed cell always carries a
## mark or a weight, never a hue alone. The kind and the ground are BOUND
## STYLES read from the value: a value crossing a threshold changes what
## the cell wears in place, and the cell is the same piece before and after.
## A format naming no ground leaves the cell on CELL, which draws nothing.

# the way the sorted column is going, in words beside its name
const UP := " ^"
const DOWN := " v"
const HEAD := &"TableHead"
const HEADING := &"TableHeading"
const ROW := &"TableRow"
const CELL := &"TableCell"


## The table: the headings across the top, then a line per row - from the
## long list's slots, given one, or from the rows kept by key. Its
## options: key, what a row is kept by; sorts, the action a heading
## presses, and sort, the bound value saying which column it is by now;
## long, a long list whose slots the lines come from instead; and style.
const OPTIONS: Array[String] = ["key", "sorts", "sort", "long", Options.STYLE]

static func make(ui: Ui, rows: Bound, columns: Array, options: Dictionary = {}) -> Desc:
	Options.checked("a table", options, OPTIONS)
	var sorts: StringName = options["sorts"]
	var sort: Bound = options["sort"]
	var long: Variant = options.get("long")
	var headings: Array = []
	# every column, its heading grown by the same share its cells are
	for column: Dictionary in columns:
		headings.append(heading(ui, column, sort, {sorts = sorts}))
	var line := func(item: Bound) -> Desc: return _line(ui, columns, item)
	var lines: Desc = ui.virtual_list(long, line) if long != null else ui.scroll(ui.each(rows, line, options["key"]))
	return ui.column([ui.row(headings, HEAD), lines.grow()], options.get(Options.STYLE, &"Table"))


## One heading: the column's words - in this kind, or plain - with the way
## marked on them while the sort is by this column, pressed to sort by it;
## a long table's (long_table.gd) as well as this one's.
## Its options: sorts, the action the press dispatches, and words_kind,
## the kind the column's words are said in.
const HEADING_OPTIONS: Array[String] = ["sorts", "words_kind"]

static func heading(ui: Ui, column: Dictionary, sort: Bound, options: Dictionary = {}) -> Desc:
	Options.checked("a table heading", options, HEADING_OPTIONS)
	var sorts: StringName = options["sorts"]
	var words_kind: StringName = options.get("words_kind", &"")
	var words: Variant = column["words"]
	var name: String = column["name"]
	var shown: Bound = sort.map(func(by: Dictionary) -> Variant: return Phrase.joined([words, "" if by["column"] != name else UP if by["ascending"] else DOWN]))
	return ui.pressable(sorts, {"column": name}, [ui.text(shown, words_kind)], HEADING).basis(0.0).grow(column["share"])


## One line: a cell per column, each from no width at all and grown by its
## column's share, so it starts where the heading does.
static func _line(ui: Ui, columns: Array, item: Bound) -> Desc:
	var cells: Array = []
	# every column, its cell for this row
	for column: Dictionary in columns:
		cells.append(_cell(ui, column, item).basis(0.0).grow(column["share"]))
	return ui.row(cells, ROW)


## One cell: the column's own description of it, or the value's words -
## dressed by the column's format, given one.
static func _cell(ui: Ui, column: Dictionary, item: Bound) -> Desc:
	if column.has("cell"):
		return column["cell"].call(item) as Desc
	var value: Bound = item.field(column["name"])
	if not column.has("format"):
		return ui.text(value)
	return _dressed(ui, value, column["format"])


## A dressed cell: the words and their mark, in the kind the format gives,
## on the ground it gives - each a bound value over the cell's own.
static func _dressed(ui: Ui, value: Bound, format: Callable) -> Desc:
	var look: Bound = value.map(func(item: Variant) -> Dictionary: return _dress(item, format))
	return ui.surface(look.field("style"), [ui.text(look.field("words"), look.field("kind"))])


## What one value wears: its words with the format's mark after them, the
## kind they are in, and the ground, which the format may leave out.
static func _dress(item: Variant, format: Callable) -> Dictionary:
	var look: Dictionary = format.call(item)
	var dress := {"words": str(item) + look["mark"], "kind": look["kind"], "style": look["style"] if look.has("style") else CELL, "mark": look["mark"]}
	# a developer's build alone, where it can still be fixed: two dresses told apart by colour and nothing else
	if OS.is_debug_build() and FormatMarks.clashes(format.hash(), dress):
		push_error("a table format dresses %s as %s on %s under the same mark as a value it dresses differently: a reader who cannot see the colour is told nothing" % [dress["words"], dress["kind"], dress["style"]])
	return dress
