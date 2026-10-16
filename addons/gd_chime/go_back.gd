extends Node

const Driver := preload("driver.gd")
const Commands := preload("commands.gd")

## The one Back of an application: the system's go-back - Android's back
## gesture and button - and the cancel key, Escape or a pad's B, each taken
## as Back by the app the reader is in.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## BACK IS THE MOVER'S GOES_BACK, THROUGH THE DOOR, dispatched in the
## innermost place taking input as a press there would be, so a place that
## asks before it is left asks (leave_guard.gd). It lowers the top pop-up -
## by the model's own way out, for one a model presents (describe_places.gd)
## - else goes back a screen. AT THE APP'S ROOT, where there is nothing to
## go back to, the app's at_root runs instead (chime_app.gd): nothing,
## unless the host says - asking before the game quits is the host's - and
## the cancel key is left untaken, going on to the host as a key no app
## takes does (easel.gd).
##
## ONE APP ANSWERS. The engine tells every node in the window of a go-back,
## so two apps in one window would both go back: it is answered only while
## a key would go on to this app's canvas - a control of it holds the
## window's focus, or held it last and nothing holds it now (easel.gd). The
## cancel key reaches this by that same road. It is heard after the
## shortcuts (shortcuts.gd), which stand after this beside the app: where a
## place on the top path declares an action on the key - a pop-up's close -
## that press is made and this hears nothing.
##
## A HIDDEN APP ANSWERS NEITHER: while its easel is not shown - the host
## showing something else in its place - the go-back and the cancel key are
## the host's, the key left untaken to go on to it: Back would move a screen
## the reader cannot see, or run the app's at_root under what they can.
##
## IT NEVER QUITS THE GAME, and the engine must not either: a project that
## leaves application/config/quit_on_go_back on is quit by the engine on the
## go-back before any app hears it, which needed_settings.gd reports.

## The app this is Back for, the easel it stands on.
var _app: Control
var _driver: Driver
var _commands: Commands


func _init(app: Control, moves: Driver, door: Commands) -> void:
	_app = app
	_driver = moves
	_commands = door


## The system's go-back, told to every node in the window: Back, where the
## app is shown and a key would go on to its canvas, as the easel routes one.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and _app.is_visible_in_tree() and _app._propagate_input_event(InputEventKey.new()):
		_go_back()


## The cancel key, which nothing on the screen took: Back while the app is
## shown, and taken where Back has somewhere to go.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and _app.is_visible_in_tree() and _go_back():
		get_viewport().set_input_as_handled()


## Back as the reader asks it: through the door in the place taking input,
## or the app's at_root where there is nothing to go back to; whether it
## had somewhere to go.
func _go_back() -> bool:
	if not _driver.can_go_back():
		_app.at_root.call()
		return false
	_commands.dispatch(_driver.get_top().back(), Driver.GOES_BACK, {})
	return true
