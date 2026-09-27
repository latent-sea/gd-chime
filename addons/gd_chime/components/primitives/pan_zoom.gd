extends "canvas.gd"

const Commands := preload("../../commands.gd")

## A canvas the reader moves: dragged by its empty space it pans, turned
## by the wheel it zooms, and a press on it picks whatever is under the
## pointer - each a command to the model that holds the view.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## The view - where the graph is and how large - is the model's, never
## this control's: a drag dispatches the pan action with the pointer's
## movement, the wheel the zoom action with its steps, and a press the pick
## action with what the hit function - a recipe's, given the point in the
## canvas - answers, or nothing for empty space. The model refuses what it
## will not do, and the paint reads the view back through the bound value.
## The pointer's press is read here rather than by the press hook, because
## a press on empty space starts a drag and a press on a node picks it, and
## only the movement after tells them apart.

var _commands: Commands
var _pans: StringName
var _zooms: StringName
var _picks: StringName
var _hit: Callable
var _dragging: bool = false
var _moved: bool = false


func _init(ui: RefCounted, paint: Callable, content: Variant, actions: Dictionary, hit: Callable, in_region: StringName, style: StringName) -> void:
	super(ui.chimes, paint, content, in_region, style)
	_commands = ui.commands
	_pans = actions.get("pans", &"")
	_zooms = actions.get("zooms", &"")
	_picks = actions.get("picks", &"")
	_hit = hit
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT:
			if click.pressed:
				_dragging = true
				_moved = false
			else:
				# a press that never moved picks what is under it
				if _dragging and not _moved and _picks != &"":
					var picked: Variant = _hit.call(click.position) if _hit.is_valid() else null
					if picked != null:
						_commands.dispatch(region, _picks, {"picked": picked})
				_dragging = false
		elif click.pressed and _zooms != &"" and (click.button_index == MOUSE_BUTTON_WHEEL_UP or click.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_commands.dispatch(region, _zooms, {"steps": 1 if click.button_index == MOUSE_BUTTON_WHEEL_UP else -1, "at": click.position})
	elif event is InputEventMouseMotion and _dragging and _pans != &"":
		_moved = true
		_commands.dispatch(region, _pans, {"by": (event as InputEventMouseMotion).relative})


static func build(ui: RefCounted, desc: RefCounted, parent: Node) -> Control:
	var made: Control = ui.primitive(&"pan_zoom").new(ui, desc.props["paint"], desc.props["content"], desc.props["actions"], desc.props["hit"], ui.region(), desc.props["style"])
	ui.attach(made, parent, desc.facts)
	return made
