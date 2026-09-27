extends RefCounted

const Commands := preload("../../commands.gd")
const LongList := preload("../../long_list.gd")
const Driver := preload("../../driver.gd")
const Applier := preload("../../applier.gd")

## The row a virtual list (virtual_list.gd) stands at, kept with the view.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE ROW IT STANDS AT IS KEPT WITH THE VIEW - the history entry the reader
## is on (driver.keep) - as a scroll keeps its offset (scroll.gd); a row, and
## not pixels, since the list is looked at by rows. Where the list is
## looking is the list's, moved by its commands, so a view is taken back to
## its row by the same command the wheel sends, once the driver's bell has
## finished ringing, since nothing is dispatched from inside one. A row past
## the list's end is the list's to bring back within it; one before its
## pages have landed is no bound at all (long_list.gd). A view nothing was
## kept for is a fresh visit: when the place the list sits in was entered
## afresh by the move - its token new - it is taken to its first row; when
## that place stayed, it is left as it stands.


## Where the list stood on one view - the first row showing - kept with that view's history entry.
class Left extends RefCounted:
	var first: int = 0


var _commands: Commands
var _list: LongList
var _driver: Driver
var _place: Node  # the place the list was built in, or none
var _left: Left = null  # where the list stands on the view shown now, or none while no view shows it
var _stay: RefCounted = null  # the token of that place's stay the list last stood in


func _init(commands: Commands, list: LongList, driver: Driver, place: Node) -> void:
	_commands = commands
	_list = list
	_driver = driver
	_place = place


## The reader moved: the view left keeps the row the list stood at, and the
## view arrived on is taken back to its own - answered whether this list,
## the control given, is shown there.
func navigated(control: Control) -> bool:
	if _left != null:
		_left.first = _list.get_first()
	_left = null
	if not Applier.shows(_driver.get_state(), control, _driver.index):
		return false
	var kept_as := StringName("rows at %s" % control.get_path())
	var afresh: bool = _place != null and _place.token != _stay
	_stay = _place.token if _place != null else null
	_left = _driver.kept(kept_as) as Left
	if _left == null:
		_left = Left.new()
		_left.first = 0 if afresh else _list.get_first()
		_driver.keep(kept_as, _left)
		if not afresh:
			return true
	_go_back_to.call_deferred(_left)
	return true


## Back to the row a view stood at - unless the reader has moved on since, or it stands there already.
func _go_back_to(left: Left) -> void:
	if left == _left and _list.get_first() != left.first:
		_commands.dispatch(_place.name, LongList.SCROLL_ROWS, {"by": left.first - _list.get_first()})
