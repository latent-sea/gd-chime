extends "controller.gd"

const Commands := preload("commands.gd")
const Token := preload("token.gd")
const HeldPages := preload("held_pages.gd")
const Reads := preload("reads.gd")

## A long list: more rows than fit on a screen, held a page at a time near
## the look, which is this model's too.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The rows live in a SOURCE this is handed as one function,
## fetch(first, count, answer). The source answers later, on the main
## thread, by calling answer(rows, total) with the rows from first and the
## length of the whole list, or null for the rows, meaning it could not. A
## row is opaque: nothing here knows what the rows are or why they changed.
##
## TWO FACTS, EACH A VALUE ON A BELL OF ITS OWN, one timing with every other
## fact: THE LOOK and THE PAGES HELD. Whatever reads one follows it, as a
## read of any value is followed, and is not woken by the other.
##
## THE LOOK is this model's: the first row showing and how many show. A
## screen holds no offset; it reads get_first() and draws. The look moves
## only by command - the four SCROLLs, SCROLL_ROWS (by the payload's rows,
## the wheel's), SHOWS {count}, how many rows fit where it is shown, and
## ASK_AGAIN, registered in its own region; a scroll up at the top or down
## at the end is refused (would), the rest clamped to the first rows that
## still fill the screen. It is set when the first row or how many show
## changes, never for a move that went nowhere.
##
## THE PAGES are held_pages.gd's: a move asks the source, each once, for the
## pages covering the look and one either side that are not held, on the
## way or failed; a page landed is kept, the farthest let go past KEEP,
## which is at least the pages one look covers plus two. An answer of null
## means the source could not give that page: has_failed(index) is true for
## every row of it, and a look covering it does not ask again - a screen
## shows the failure where the rows would be. ASK_AGAIN forgets every
## failure and asks again. A page landing, a page failing and failures
## forgotten each set the pages again; forgetting everything, as a reset or
## a drop does, does not, since what is shown stands until the pages asked
## for land. Why the source could not is the source's to report, to the
## developer's log.
##
## What is held is read by index: count(), has(index), get_item(index) -
## null for one not held, a screen's dots. has_failed(index) tells a row
## that could not come from one still coming.
##
## The rows change under this. It is built with a bound value reading
## whatever the rows move with - the source's model - and follows what that
## read (reads.gd); as it moves it resets: everything forgotten, its token
## reissued, the look's pages asked for again, and set again as they land.
## An answer carries the token it was asked under (token.gd); one whose
## token is dead is dropped.
##
## DATA LOADS WHEN SHOWN. Built, this holds and asks for nothing until
## look(token): the place it sits in calls it as it fills, with the token of
## the stay, and this issues its own under it, dead with it. drop(), as the
## place empties, forgets but keeps the look; not looking, a move asks nothing.
##
## Deliberately absent: a margin wider than one page, row identity, and a
## total before the first answer (count() is 0 until a page lands).

const SCROLL_ROW_UP := &"scroll_row_up"
const SCROLL_ROW_DOWN := &"scroll_row_down"
const SCROLL_PAGE_UP := &"scroll_page_up"
const SCROLL_PAGE_DOWN := &"scroll_page_down"
const SCROLL_ROWS := &"scroll_rows"
const SHOWS := &"shows_rows"
const ASK_AGAIN := &"ask_again"
## Every action a long list is told.
const COMMANDS: Array[StringName] = [SCROLL_ROW_UP, SCROLL_ROW_DOWN, SCROLL_PAGE_UP, SCROLL_PAGE_DOWN, SCROLL_ROWS, SHOWS, ASK_AGAIN]

var _fetch: Callable
var _page: int
var _look_moved := OwnBell.new("look")  # the bell the look rings
var _pages_moved := OwnBell.new("pages")  # the bell the pages held ring
var _showing: Value  # how many rows show, made as this is built
var _first := value(0, _look_moved)  # the first row showing
var _held: Value  # the pages held (held_pages.gd), made as this is built, changed in place and set again
var _token: Token = Token.new()  # carried by every request, issued under the place's: dead with it or on a reset
var _under: Token = null
var _looking: bool = false  # between look() and drop(): the source is asked for the look's pages
var _rows: Bound  # whatever the rows move with, read to follow it


func _init(chimes: Chimes, fetch: Callable, page: int, keep: int, showing: int, rows: Bound) -> void:
	super(chimes, [], own_region("long_list"))
	_look_moved.hang(chimes)
	_pages_moved.hang(chimes)
	_fetch = fetch
	_rows = rows
	_page = page
	_showing = value(showing, _look_moved)
	_held = value(HeldPages.new(page, keep), _pages_moved)
	follow(&"rows", _rows_moved)


## Start looking under this token: the look's pages asked for, and kept so.
func look(under: Token) -> void:
	_under = under
	_looking = true
	_forget()
	_look()


## Stop looking: everything forgotten, the look kept.
func drop() -> void:
	_looking = false
	_forget()


## How long the whole list is, as the source last said. 0 until a page lands.
func count() -> int:
	return _held.read().count()


## The first row showing.
func get_first() -> int:
	return _first.read()


## How many rows show.
func get_showing() -> int:
	return _showing.read()


## Whether the row at this index is held. An index past the end is not, even
## when the page it would fall on is.
func has(index: int) -> bool:
	return _held.read().has(index)


## Whether the row at this index falls on a page the source could not give.
func has_failed(index: int) -> bool:
	return _held.read().has_failed(index)


## The row at this index, or null if it is not held.
func get_item(index: int) -> Variant:
	return _held.read().get_item(index)


## A scroll past the top or the end, as the look and the total now stand, is refused.
func would(action: StringName, _payload: Dictionary) -> Phrase:
	if [SCROLL_ROW_UP, SCROLL_PAGE_UP].has(action) and get_first() == 0:
		return Phrase.of("Already at the top")
	if [SCROLL_ROW_DOWN, SCROLL_PAGE_DOWN].has(action) and count() > 0 and get_first() >= count() - get_showing():
		return Phrase.of("Already at the end")
	return null


func told(action: StringName, payload: Dictionary) -> Phrase:
	var first: int = _first.read()
	match action:
		SCROLL_ROW_UP: _move_to(first - 1)
		SCROLL_ROW_DOWN: _move_to(first + 1)
		SCROLL_PAGE_UP: _move_to(first - _showing.read())
		SCROLL_PAGE_DOWN: _move_to(first + _showing.read())
		SCROLL_ROWS: _move_to(first + payload["by"])
		SHOWS:
			_showing.set_value(payload["count"])
			_move_to(first)
		ASK_AGAIN:
			var held: HeldPages = _held.read()
			if held.forget_failures():
				_held.set_value(held)
			_look()
	return null


## The rows changed under this: forget everything, ask again for the look.
func reset() -> void:
	_forget()
	_look()


## What the rows move with read, so it is followed; moved, a reset - apart
## from what is followed, so the pages it asks for and their landing are
## never among it (reads.gd).
func _rows_moved() -> void:
	_rows.read()
	Reads.apart(reset)


## Everything held forgotten in place, and not set: what is shown stands
## until the pages asked for land.
func _forget() -> void:
	(_held.read() as HeldPages).forget()
	_token.cancel()
	_token = Token.new(_under)


## The first row clamped and, if it changed, set; the look's pages asked for.
func _move_to(first: int) -> void:
	var showing: int = _showing.read()
	# an unknown total (0 until a page lands) is no bound; a known one is the last first row that fills the screen
	var clamped := maxi(first, 0) if count() == 0 else clampi(first, 0, maxi(count() - showing, 0))
	if clamped != _first.read():
		_first.set_value(clamped)
	_look()


## The look's pages the held pages want, asked for - and only while looking.
func _look() -> void:
	if not _looking:
		return
	# every page wanted, asked of the source under the token it goes with
	for page: int in (_held.read() as HeldPages).wanted(_first.read(), _showing.read()):
		_fetch.call(page * _page, _page, _landed.bind(page, _token))


## An answer from the source, bound with the page it is for and the token it
## was asked under. A total that shrank pulls the look back as the pages are
## set, so a screen drawing on them reads the first row it will keep.
func _landed(rows: Variant, total: int, page: int, token: Token) -> void:
	if not token.is_live():
		return
	var held: HeldPages = _held.read()
	if rows == null:
		held.failed(page)
	else:
		held.landed(page, rows, total)
		_move_to(_first.read())
	_held.set_value(held)


## Every action this model is told.
func answers() -> Array[StringName]:
	return COMMANDS
