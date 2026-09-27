extends "controller.gd"

const Commands := preload("commands.gd")
const Measures := preload("measures.gd")
const TableModels := preload("table_models.gd")

## What stands behind a figure: the rows it counted, in a data grid
## (data_grid.gd) scoped to exactly them (queried_rows.gd, scope_to).
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## SHOWS_ROWS_BEHIND is pressed on a figure - a KPI card, carrying {"figure": its
## name} - or on a split's bar or region, carrying {"picked": its word}, the
## payload a bar and a map region press with, so a bar's context menu
## offers it on the bar's own payload; a bare pick drills into the split
## named as this is built. Either way the grid's view is scoped to the
## rows the dashboard's measures say that figure stands for now
## (measures.gd, clauses_of) - the very rows it counted - beneath whatever
## filters the reader then builds on the grid, and the title says which.
## The press goes to the grid's place; this answers it first.
##
## Deliberately absent: a drill from inside a drill - the grid's rows are
## rows, not figures.

const SHOWS_ROWS_BEHIND := &"shows_the_rows_behind"
## The one action this is told.
const COMMANDS: Array[StringName] = [SHOWS_ROWS_BEHIND]

var _measures: Measures
var _models: TableModels
var _words: Dictionary  # figure or split name -> what it is called
var _split: StringName
var _asked := value({})  # the last press drilled on


## Scoping these models' view by these measures; each figure's words, and the split a bare pick drills into.
func _init(chimes: Chimes, measures: Measures, models: TableModels, words: Dictionary, split: StringName) -> void:
	super(chimes)
	_measures = measures
	_models = models
	_words = words
	_split = split


## What the rows shown stand behind: a figure, or a split's word - the rows of a region.
func get_title() -> Variant:
	var asked: Dictionary = _asked.read()
	if asked.is_empty():
		return ""
	var named: Variant = _words[asked.get("figure", _split)]
	return named if not asked.has("picked") else Phrase.with("%s in %s", [named, asked["picked"]])


func told(_action: StringName, payload: Dictionary) -> Phrase:
	_asked.set_value(payload)
	_models.view.scope_to(_measures.clauses_of(payload.get("figure", _split), payload.get("picked")))
	return null


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
