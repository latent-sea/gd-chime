extends "res://addons/gd_chime/application.gd"

const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const Layer := preload("res://demo/grid/layer.gd")
const TableModel := preload("res://demo/grid/table_model.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Loading := preload("res://addons/gd_chime/components/recipes/loading.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## Ten lines over an array that lives on another thread.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/grid/grid.gd
##
## The layer holds the array and serves it from a worker thread, a page at a
## time, slowly on purpose. The model asks for pages, keeps what lands, and
## holds where the table is looking; the table is ten lines, each a bound
## value reading its slot off the model - its arrival if landed, loading's
## own shape standing in and a fetch if not. Press ADD ONE and the layer holds a core for five seconds
## before answering: the status says so, the frame count at the bottom keeps
## climbing, and UP and DOWN still work. Press DOWN past what has landed and
## the shapes fill in a page at a time.
##
## A button that cannot do anything right now says why under its words: ADD
## ONE while an add is on its way, UP at the top. UP and DOWN keep scrolling
## while held. The standard wiring is application.gd's; this file answers
## its questions and never listens.

const REGION := &"grid"
const HOLD_ADD_MS := 5000
const HOLD_PAGE_MS := 700
const ALREADY := 25
const SHOWING := 10
## A held UP or DOWN: the wait before it repeats, then how often, in seconds.
const REPEAT_WAIT := 0.4
const REPEAT_INTERVAL := 0.08
const BUTTONS := {TableModel.SCROLL_TABLE_UP: ["Up"], TableModel.SCROLL_TABLE_DOWN: ["Down"], TableModel.ADD_ARRIVAL: ["Add one"]}

var _layer: Layer


func look() -> Theme:
	return DemoTheme.new()


func declare(register: Actions) -> void:
	register.declare_all(BUTTONS)


func describe() -> Desc:
	_layer = Layer.new(HOLD_ADD_MS, HOLD_PAGE_MS, ALREADY)
	return _app(TableModel.new(chimes, _layer))


## The app: the table and the pulse on the left, the three buttons down the right.
func _app(arrivals: TableModel) -> Desc:
	var buttons: Array = [ui.button(TableModel.SCROLL_TABLE_UP).grow().repeats(REPEAT_WAIT, REPEAT_INTERVAL), ui.button(TableModel.SCROLL_TABLE_DOWN).grow().repeats(REPEAT_WAIT, REPEAT_INTERVAL), ui.button(TableModel.ADD_ARRIVAL).grow()]
	var pulse := ui.text(ui.every_frame(func() -> Phrase: return Phrase.with("Main thread: frame %d", [Engine.get_process_frames()])), DemoTheme.READOUT)
	var left := ui.column([_table(arrivals).grow(), pulse.basis(0.1)])
	# the arrivals answer in the app's region, where its buttons are described
	return ui.app(REGION, [ui.row([left.grow(6.0), ui.column(buttons).grow(1.0)])], arrivals)


## The table: a line per slot reading the model, and the status under them.
func _table(arrivals: TableModel) -> Desc:
	var lines: Array = []
	# every slot, its line a bound value on the model's bells
	for slot: int in range(SHOWING):
		var said: Bound = ui.bound(arrivals.get_first).map(func(first: int) -> Variant: return _line(arrivals, first + slot))
		lines.append(ui.when(said.map(func(words: Variant) -> bool: return words != null), ui.text(said, DemoTheme.LINE), Loading.shapes(ui, 1)).grow())
	var status: Bound = ui.bound(arrivals.get_busy).map(func(busy: bool) -> Phrase: return Phrase.of("Adding: the layer is holding a core for 5s") if busy else Phrase.of("Table landed"))
	lines.append(ui.text(status, DemoTheme.LINE))
	return ui.surface(Themes.CARD, [ui.column(lines, DemoTheme.TIGHT)])


## One row: its arrival if landed, nothing and a fetch if not - the slot
## then standing in loading's shape - and nothing past the end.
static func _line(model: TableModel, index: int) -> Variant:
	if index >= model.count():
		return ""
	if model.has(index):
		return Phrase.with("Arrival %d", [model.get_arrival(index)])
	model.fetch(index)
	return null


## The window is closing: join the worker, cutting a held core short.
func _finalize() -> void:
	_layer.stop()
