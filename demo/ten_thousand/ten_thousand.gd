extends "res://addons/gd_chime/application.gd"

const LongList := preload("res://addons/gd_chime/long_list.gd")
const Token := preload("res://addons/gd_chime/token.gd")
const Bound := preload("res://addons/gd_chime/components/primitives/bound.gd")
const SlowSource := preload("res://demo/ten_thousand/slow_source.gd")
const DemoTheme := preload("res://demo/demo_theme.gd")
const Loading := preload("res://addons/gd_chime/components/recipes/loading.gd")
const Phrase := preload("res://addons/gd_chime/phrase.gd")

## Ten thousand rows, twelve slots, and a node count that must not move.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## Run:  godot --path <this folder> --script res://demo/ten_thousand/ten_thousand.gd
##
## The source makes rows up as they are asked for and answers each page a
## little later, on the main thread. The long list holds a few pages near
## where it is looking and lets the rest go, and where it is looking is the
## list's own. The screen is a virtual list: twelve slots that never move,
## each reading its row through a handle - a scroll is the list's first row
## changing and the handles re-reading. Scroll with the wheel over the
## rows, or with the four buttons. Press x10 ROWS and the list is a hundred
## thousand long; /10 and it is a hundred: every slot goes to loading's own
## shape and fills back in, and a list left at row 9,990 pulls back to
## where the rows now end. Read the bottom line while you do it: the nodes alive never change.
##
## A button that cannot be used right now says why under its words - row up
## at the top, /10 rows at a hundred, the list's and the source's own refusals
## asked of the door - and a press on it dispatches nothing. The four scroll
## buttons keep scrolling while held; x10 and /10 do not.
##
## THE LIST LOADS WHEN SHOWN. It is built holding nothing, and sits in a
## place, THE ROWS: as the driver enters the rows the place fills, telling
## the list to look under the token of the stay, and the source is asked
## for the first pages then and not before; leaving would empty it, telling
## the list to drop what it holds. The standard wiring is application.gd's;
## this file answers its questions and never listens.

const APP := &"app"
const ROWS := &"rows"
const ROW_COUNT := 10000
const PAGE := 50
const KEEP := 8  # pages held: a look of twelve rows covers four at most, so this is roomy
const SHOWING := 12
## A held scroll button: the wait before it repeats, then how often, in seconds.
const REPEAT_WAIT := 0.4
const REPEAT_INTERVAL := 0.08
## The six buttons, with their words.
const BUTTONS := {LongList.SCROLL_ROW_UP: ["Row up"], LongList.SCROLL_ROW_DOWN: ["Row down"], LongList.SCROLL_PAGE_UP: ["Page up"], LongList.SCROLL_PAGE_DOWN: ["Page down"], SlowSource.GROW_ROWS_TENFOLD: ["×10 rows"], SlowSource.SHRINK_ROWS_TENFOLD: ["/10 rows"]}

func look() -> Theme:
	return DemoTheme.new()


func declare(register: Actions) -> void:
	register.declare_all(BUTTONS)


func describe() -> Desc:
	# both answer from anywhere: the six buttons stand in the app and the rows' virtual list inside the screen
	var source: SlowSource = model(SlowSource.new(chimes, ROW_COUNT))
	var list: LongList = model(LongList.new(chimes, source.fetch, PAGE, KEEP, SHOWING, ui.bound(source.count)))
	return _app(list, source)


## The app: the rows and the readout on the left, the six buttons down the right.
func _app(list: LongList, source: SlowSource) -> Desc:
	var rows := ui.screen(ROWS, [ui.virtual_list(list, _slot)], null, {on_fill = func(token: Token) -> void: list.look(token), on_empty = list.drop})
	var buttons: Array = []
	# the six buttons, the four scroll buttons repeating while held
	for action: StringName in BUTTONS:
		var button := ui.button(action).grow()
		if [LongList.SCROLL_ROW_UP, LongList.SCROLL_ROW_DOWN, LongList.SCROLL_PAGE_UP, LongList.SCROLL_PAGE_DOWN].has(action):
			button.repeats(REPEAT_WAIT, REPEAT_INTERVAL)
		buttons.append(button)
	var left := ui.column([rows.grow(), _readout(list, source).basis(0.1)])
	return ui.app(APP, [ui.row([left.grow(6.0), ui.column(buttons).grow(1.0)])])


## A slot: its row, or loading's one shape standing in while the row is not here.
func _slot(handle: Bound) -> Desc:
	# a row is its number; the bar is number mod 20 marks long, so a page boundary passing shows
	var said := ui.text(handle.map(func(row: Variant) -> Variant: return "" if row == null else Phrase.with("Row %d   %s", [row, "|".repeat(int(row) % 20)])), DemoTheme.LINE)
	return ui.when(handle.map(func(row: Variant) -> bool: return row != null), said, Loading.shapes(ui, 1))


## The bottom line, read every frame: the list's length and look, the
## source's queue, and the nodes alive - which must not move.
func _readout(list: LongList, source: SlowSource) -> Desc:
	var line: Bound = ui.every_frame(func() -> Phrase: return Phrase.with("%d rows   top row %d   %d on the way   %d nodes alive", [list.count(), list.get_first() + 1, source.get_waiting(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))]))
	return ui.text(line, DemoTheme.READOUT)
