extends "res://addons/gd_chime/controller.gd"

const GdChime := preload("res://addons/gd_chime/gd_chime.gd")
const Warehouse := preload("res://demo/apps/workspace/warehouse.gd")

## The workspace's work: the project's queries and their words, the query
## in front written and run, what it answered, and the dataset whose
## columns the inspector shows - the demo's one model beside the shell's.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## WHICH QUERIES ARE OPEN, AND WHICH IS IN FRONT, ARE THE DOCUMENTS' (the
## floor's documents.gd, handed in); this holds every query's words and
## writes and runs the one in front. Every change is a command: WRITES
## {text} as the editor changes, RUNS the query in front, MAKES a new one,
## COPIES one, SHOWS a dataset's columns, PREVIEWS a dataset in a new query
## run at once, and PUTS_IN a dataset's name at the end of the query in
## front. Each refuses what it cannot do, in words - nothing open to run,
## nothing open to write a name into - so a refused press says why wherever
## it is: on a button, in the palette, in a context menu.
##
## A run that finishes says so in the application's notifications, with
## the offer to bring the results into view (SHOWS_RESULTS, the panels'),
## and hands its rows and columns to the results' table (table_models.gd,
## replace), where the reader sorts, picks and scrolls them as in any grid.
##
## The queries' words, what the last run answered and the dataset shown
## are values (value.gd), set as they move - one model's, so its readers
## read again together, once a frame.
## Its queries and the dataset shown are kept between runs (saved, restore).

const WRITES := &"writes_the_query"
const RUNS := &"runs_the_query"
const MAKES := &"makes_a_query"
const COPIES := &"copies_a_query"
const SHOWS := &"shows_a_dataset"
const PREVIEWS := &"previews_a_dataset"
const PUTS_IN := &"puts_the_name_in"
## What a finished run's notification offers: the results brought into view, which the panels answer.
const SHOWS_RESULTS := &"shows_the_results"
## Every action this is told; the results pane answers the last of them too.
const COMMANDS: Array[StringName] = [WRITES, RUNS, MAKES, COPIES, SHOWS, PREVIEWS, PUTS_IN]

## The queries open, made here over the queries this holds.
var documents: GdChime.Documents
var notices: GdChime.Notifications  # the application's, handed in: a run that finishes says so there
var table: GdChime.TableModels  # handed in: every run's rows and columns go to it
var _queries := value(Warehouse.QUERIES.duplicate())  # a query's file name -> its words
var _shown := value(null)  # the dataset whose columns the inspector shows, or none
var _results := value({"columns": [], "rows": [], "total": 0, "said": null, "failed": false, "ran": false, "took": 0.0})
var _catalogue: Array = Warehouse.catalogue()


## Over the application's notifications and the table a run's rows land in;
## the queries open are made here, over the queries this holds.
func _init(chimes: Chimes, notifications: GdChime.Notifications, results: GdChime.TableModels) -> void:
	super(chimes)
	notices = notifications
	table = results
	documents = GdChime.Documents.new(chimes, Bound.new(get_queries))
	add_child(documents)


## Every query of the project, {value, words}: its file name as both.
func get_queries() -> Array:
	return _queries.read().keys().map(func(named: String) -> Dictionary: return {"value": named, "words": named})


## Every dataset in the warehouse, {value, words}.
func get_datasets() -> Array:
	return _catalogue


## The datasets the project uses, {value, words}.
func get_project() -> Array:
	return Array(Warehouse.PROJECT).map(func(named: String) -> Dictionary: return {"value": named, "words": named})


## The words of the query in front, or none while none is open.
func get_words() -> Variant:
	return null if documents.get_front() == null else _queries.read()[documents.get_front()]


## What the last run answered: {columns, rows, total, said, failed, ran, took}.
func get_results() -> Dictionary:
	return _results.read()


func get_shown() -> Variant:
	return _shown.read()


## The columns of the dataset shown, {name, kind} each.
func get_columns() -> Array:
	return [] if _shown.read() == null else Warehouse.columns_of(_shown.read()).map(func(column: Array) -> Dictionary: return {"name": column[0], "kind": column[1]})


func would(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		WRITES, RUNS:
			return Phrase.of("No query is open") if documents.get_front() == null else null
		PUTS_IN:
			return Phrase.of("Open a query to put the name in") if documents.get_front() == null else null
		SHOWS, PREVIEWS:
			return null if payload.get("value") != null and not Warehouse.columns_of(str(payload["value"])).is_empty() else Phrase.with("There is no dataset called %s", [payload.get("value")])
		COPIES:
			return null if _queries.read().has(payload.get("value")) else Phrase.of("There is no such query to copy")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	match action:
		WRITES:
			_queries.read()[documents.get_front()] = payload["text"]
			_queries.set_value(_queries.read())
		RUNS:
			_run()
		MAKES:
			_make("select *\nfrom sales.orders\nlimit 100")
		COPIES:
			_make(_queries.read()[payload["value"]])
		SHOWS:
			_shown.set_value(payload["value"])
		PREVIEWS:
			_shown.set_value(payload["value"])
			_make("select *\nfrom %s\nlimit 100" % payload["value"])
			_run()
		PUTS_IN:
			_queries.read()[documents.get_front()] = "%s\n%s" % [_queries.read()[documents.get_front()], payload["value"]]
			_queries.set_value(_queries.read())
	return null


## The query in front run, and what it answered kept, with how long it
## took - its rows and columns handed to the results' table.
func _run() -> void:
	var began := Time.get_ticks_usec()
	_results.set_value(Warehouse.run(_queries.read()[documents.get_front()]))
	_results.read()["took"] = (Time.get_ticks_usec() - began) / 1000.0
	_results.read()["ran"] = true
	table.replace(_rows_of(_results.read()), _results.read()["columns"].map(func(column: String) -> Dictionary: return {"name": StringName(column), "words": column, "share": 1.0 / _results.read()["columns"].size()}))
	_results.set_value(_results.read())
	# finished, said where the notifications stand: a failure in its own words, rows with the offer to see them
	if _results.read()["failed"]:
		notices.notify(Phrase.with("%s did not run: %s", [documents.get_front(), _results.read()["said"]]))
	else:
		notices.notify(Phrase.with("%s finished: %d rows", [documents.get_front(), _results.read()["total"]]), SHOWS_RESULTS)


## A run's rows held as the results' table holds them: every column words,
## each value as the warehouse wrote it.
static func _rows_of(ran: Dictionary) -> GdChime.PackedRows:
	var kinds: Dictionary = {}
	# every column the run answered, a words column of that name
	for column: String in ran["columns"]:
		kinds[StringName(column)] = GdChime.PackedRows.WORDS
	var rows := GdChime.PackedRows.new(kinds)
	# every row the run kept to show, its values in the columns' order
	for row: Array in ran["rows"]:
		rows.add(row)
	return rows


## A new query of these words, under the first free name, opened in front.
func _make(words: String) -> void:
	var at := 1
	# every number from one, for the first no query is named by
	while _queries.read().has("query_%d.sql" % at):
		at += 1
	_queries.read()["query_%d.sql" % at] = words
	_queries.set_value(_queries.read())
	documents.open("query_%d.sql" % at)


## The queries' words and the dataset shown, as plain data.
func saved() -> Dictionary:
	return {"queries": _queries.read().duplicate(), "shown": _shown.read()}


## Read back whole: every query a name and its words, and the dataset shown
## or none (save_shape.gd); else said, and kept as it is.
func restore(save: Dictionary) -> void:
	if GdChime.SaveShape.refused(GdChime.SaveShape.record({"queries": GdChime.SaveShape.keyed(GdChime.SaveShape.words(), GdChime.SaveShape.words()), "shown": GdChime.SaveShape.maybe(GdChime.SaveShape.words())}), save, "the workspace's queries"):
		return
	_queries.set_value(save["queries"])
	_shown.set_value(save["shown"])


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
