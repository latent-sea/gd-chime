extends RefCounted

const Commands := preload("../../commands.gd")
const LongList := preload("../../long_list.gd")

## A virtual list's cursor (virtual_list.gd): what its keys, its pad and a
## pointer's presses mean, each a command, and bringing the row the cursor
## is on into the rows shown - the input the list takes as its own.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## GIVEN A CURSOR, THE LIST IS ONE PLACE TO BE IN, as a table is: the list
## itself takes the focus, and the row the reader is on is a model's - AT, a
## bound value reading the cursor's place (row_selection.gd) - drawn by the
## template, never by the focus walking from slot to slot. Every command
## goes to the cursor's REGION. Its KEYS are each [input action, with shift
## held, command, payload]; its ANYWHERE keys, heard while the focus is
## anywhere within the list - a line being typed into a cell - are [input
## action, command], the first the door would not refuse taken, so escape
## gives up an edit and, with none, clears. A press of the pointer on a slot
## is its PRESSES command carrying {at, across, adds, extends} - the place,
## the column under the pointer where the slot can say (cells.gd), and
## whether control or shift was held - and a second press in quick
## succession its TWICE command as well. The cursor moving, the list is
## scrolled, by the command the wheel sends, just far enough that its row
## shows.
##
## It holds no input of its own: the list hands it each event it takes.

var _commands: Commands
var _list: LongList
var _cursor: Dictionary  # {at, keys, anywhere, presses, twice}
var _region: StringName  # the place it is built in, where its commands are told


func _init(commands: Commands, list: LongList, cursor: Dictionary, in_region: StringName) -> void:
	_commands = commands
	_list = list
	_cursor = cursor
	_region = in_region


## The row the cursor is on: read by the list, so it follows the cursor moving.
func get_at() -> int:
	return _cursor["at"].read()


## A key the cursor names, dispatched as its command: whether it was one.
func key(event: InputEvent) -> bool:
	var shifted := event is InputEventWithModifiers and (event as InputEventWithModifiers).shift_pressed
	# every key the cursor names, for the first this event presses with shift as it names
	for named: Array in _cursor["keys"]:
		if event.is_action_pressed(named[0], true) and shifted == named[1]:
			_commands.dispatch(_region, named[2], named[3])
			return true
	return false


## A key heard anywhere within the list, as the first of its commands the
## door would not refuse: whether it was one.
func anywhere(event: InputEvent) -> bool:
	# every key heard anywhere within that this event presses, in order, until one the door does not refuse
	for named: Array in _cursor["anywhere"]:
		if event.is_action_pressed(named[0]) and _commands.refusal(_region, named[1], {}) == null:
			_commands.dispatch(_region, named[1], {})
			return true
	return false


## A press of the pointer's main button on the list: on a slot holding a
## row, the cursor's press, and twice, its second - whether it was one.
func pointer(event: InputEvent, over: Control) -> bool:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return false
	var slots: Array = over.get_slots()
	# every slot top to bottom, for the one the press landed in, if it holds a row
	for at: int in slots.size():
		var line: Control = slots[at]
		if line.get_global_rect().has_point(over.get_global_transform() * click.position) and _list.get_first() + at < _list.count():
			var column := _column_at(line, line.get_local_mouse_position().x)
			var across: Dictionary = {} if column < 0 else {"across": column}
			_commands.dispatch(_region, _cursor["presses"], {"at": _list.get_first() + at, "adds": click.ctrl_pressed, "extends": click.shift_pressed}.merged(across))
			if click.double_click:
				_commands.dispatch(_region, _cursor["twice"], {})
	return true


## The column this far across a slot, where the line it shows can say
## (cells.gd, within whatever holds it), or -1.
static func _column_at(line: Node, x: float) -> int:
	if line.has_method(&"part_at"):
		return line.part_at(x)
	# every part the slot shows, for a line that can say
	for part: Node in line.get_children():
		if part is CanvasItem and (part as CanvasItem).visible and _column_at(part, x) >= 0:
			return _column_at(part, x)
	return -1


## The list scrolled just far enough that the cursor's row is among those shown.
func follow() -> void:
	var at := get_at()
	var first := _list.get_first()
	var last := first + _list.get_showing() - 1
	if at < first or at > last:
		_commands.dispatch(_region, LongList.SCROLL_ROWS, {"by": at - first if at < first else at - last})
