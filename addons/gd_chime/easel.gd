extends SubViewportContainer

const Themes := preload("theme.gd")
const SafeArea := preload("safe_area.gd")
const Canvas := preload("easel_canvas.gd")

## The easel: the rect a host gives an application, with the application's
## canvas drawn at the base size on it and stretched to fit - the window's
## canvas_items stretch, scoped to one node's rect - with the safe rect on
## that canvas, where the app and its pop-ups stand.
##
## gd-chime. MIT licensed; see the LICENCE file at the root of this folder.
##
## THE WINDOW BELONGS TO THE HOST. An easel never writes the window's stretch
## mode or base size, its clear colour or the input map: it owns exactly its
## own subtree, and nothing outside it can notice it is there. So a game
## hosts one beside its own scenes, in a side panel or over the whole
## window, and two of them in one window have nothing to fight over.
##
## HOW IT SCALES. Its viewport renders at the real pixels of its rect, so
## words stay crisp, and draws its canvas at the BASE SIZE - the project's
## `display/window/size` - stretched to fit, the way the window's
## canvas_items stretch with aspect expand does: the canvas is scaled by the
## same factor each way, covers the whole rect, and grows past the base
## along whichever side has the room. A layout in shares of the canvas is
## therefore a layout in shares of the rect, and a size written once in the
## theme is a size on every screen. A pointer reaches the easel under it, and
## the container forwards it, so nothing about pressing changes.
##
## NEVER SMALLER THAN THE LOOK SAYS IS READABLE. A phone has a desk's pixels
## in a hand's width, so a canvas only fitted to it is drawn a fifth the
## size. The look names the least a base pixel may measure on the screen,
## `least_pixel_um` under the type Shape, in thousandths of a millimetre;
## where fitting would draw it smaller the canvas is drawn at that, and so
## holds fewer base pixels than the base. Pixels become millimetres by the
## screen's dots to the inch, which `reads_dpi` answers: the engine's own,
## until a host that knows its screen better sets another. A look that names
## none is only fitted.
##
## A KEY GOES TO THE APP HOLDING THE FOCUS. The engine keeps one focus across
## every viewport in a window, gives a key to the viewport holding it, and
## offers one that viewport leaves untaken to every other container's
## viewport before the host (measured on 4.6.2). So a key or a pad button
## goes on to the canvas only while a control here holds that focus - or,
## while nothing in the window holds it, while a control here held it last,
## since a focused control hidden or freed must not leave its app deaf. One
## this app takes is handled and never reaches the host, one it leaves goes
## on to the game, and another app never hears it. Which app held the focus
## last in a window is the floor's own to keep, never the window's, so
## nothing outside an app notices it. The easel takes no focus itself, so a
## click on the canvas's bare ground leaves the focus where it was.
##
## TURNING SWAPS THE BASE. A rect on its end drawn at a landscape base would
## be fitted by the width, every word shrunk to a stamp; so the base turns
## with the rect - the project's base, or its transpose - and a line of
## words keeps the same share of the short side either way round. A frame
## after a turn, everything on the canvas is asked what it needs again: the
## turn re-arranges screens not shown as well as the one that is, and the
## engine says nothing of a hidden thing's needs moving.
##
## THE APP STANDS IN THE SAFE RECT. Each time the canvas is fitted, how far
## in from each edge is safe is worked out (safe_area.gd) from what covers the
## rect on its screen: the system's unobscured area, which `reads_safe_area`
## answers - the engine's on a handheld, none on a desk, where the engine's
## names the taskbar a full screen window covers; the corners' radius, which
## `reads_corner_um` answers - the look's Shape/corner_um on a handheld window
## covering its screen, since the engine names no rounded corners; and, while
## a field holds the focus, the keyboard, which `reads_keyboard` answers. The
## look's gutter, Shape/edge, is on top on every side. The canvas lays every
## piece standing on it in what is left (easel_canvas.gd). The keyboard is
## read every physics frame while a field holds the focus and never
## otherwise: the engine says nothing as it rises, and focus moving into or
## out of a field fits the canvas again. On the physics frame, not the drawn
## one: an app made on the easel has a drawn frame of its own that would
## stand in its place.
##
## NEVER UNDER THE FLOOR. The scale the least pixel asks for is lowered where
## it would leave the safe room's short side under the look's Shape/floor, in
## base pixels: on a small window the type is drawn smaller rather than any
## screen given less room than it is designed at (safe_area.gd).
##
## THE GROUND IS ITS OWN. The canvas paints the look's ground across the
## whole rect, so a light look is light to the edge where nothing draws; the
## window's clear colour is never touched. The look is the canvas's Theme -
## a Theme reaches nothing through a viewport, so it is worn inside it.
##
## IT SCALES ONCE: a host that has stretched its window would scale this
## twice, which is why the settings the framework needs say the window is
## not stretched (needed_settings.gd); and a rect is measured on its screen
## in the window's own pixels, which holds while that is so.

## The project's base: what `display/window/size` says, read as the easel enters the tree.
const WIDTH := "display/window/size/viewport_width"
const HEIGHT := "display/window/size/viewport_height"

## The look's type naming the least a base pixel may measure on the screen, the gutter, the corners and the floor.
const REAL_SIZE := &"Shape"

## By each window, the easel whose canvas held its focus last, both by
## instance id: one entry a window, however many apps come and go in it.
static var _held_last: Dictionary = {}

## The viewport the canvas is drawn in, at the rect's real pixels.
var viewport := SubViewport.new()
## The canvas everything is built on, spread over the viewport, wearing the look.
var canvas := Canvas.new()
## The dots to the inch of the screen the rect is on, asked each time the canvas is fitted.
var reads_dpi: Callable = DisplayServer.screen_get_dpi
## The system's unobscured area of the screen, in its pixels, asked each time the canvas is fitted; an empty one covers nothing.
var reads_safe_area: Callable = _unobscured_on_a_handheld
## The radius of the screen's rounded corners, in thousandths of a millimetre, asked each time the canvas is fitted.
var reads_corner_um: Callable = _corners_of_a_handheld
## The keyboard's height up from the window's foot, in pixels, asked each frame while a field holds the focus.
var reads_keyboard: Callable = _keyboard_on_screen
var _base: Vector2i  # the project's base, landscape
var _turned: bool = false  # whether the base stands transposed now
var _keyboard: float = 0.0  # the keyboard's height as last read while a field held the focus; none once it lets go


func _init() -> void:
	# a click on the canvas's bare ground leaves the window's one focus where it was, on a control of the app or the host's
	focus_mode = Control.FOCUS_NONE
	stretch = true
	viewport.size_2d_override_stretch = true
	add_child(viewport)
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(canvas)
	viewport.gui_focus_changed.connect(_focused)
	# a look worn after the rect was fitted may name another least size; deferred, since the engine tells of the change before the canvas reads the new look
	canvas.theme_changed.connect(_fit, CONNECT_DEFERRED)


## The base the canvas is drawn at now: the project's, or its transpose while the rect is on its end.
func get_base() -> Vector2i:
	return Vector2i(_base.y, _base.x) if _turned else _base


## The engine's unobscured area on a handheld, which names its cutout and
## home bar; none on a desk, where it names the taskbar.
static func _unobscured_on_a_handheld() -> Rect2i:
	return DisplayServer.get_display_safe_area() if OS.has_feature("mobile") else Rect2i()


## The engine's keyboard height where its screen has a keyboard on it;
## none where it has none, which the engine would warn of being asked.
static func _keyboard_on_screen() -> int:
	return DisplayServer.virtual_keyboard_get_height() if DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD) else 0


## The look's corner radius on a handheld window covering its screen, whose
## corners are the screen's; none on any other.
func _corners_of_a_handheld() -> int:
	return canvas.get_theme_constant(&"corner_um", REAL_SIZE) if OS.has_feature("mobile") and get_window().size == DisplayServer.screen_get_size() else 0


## Whether an event goes on to the canvas: one with a place in the window
## reaches the easel under it by itself; any other - a key, a pad - only
## while a control of this app holds the window's one focus, or held it last
## and nothing in the window holds it now.
func _propagate_input_event(event: InputEvent) -> bool:
	# a pointer, a finger or a gesture: it has a place in the window
	if event is InputEventMouse or event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventGesture:
		return true
	var nowhere := get_viewport().gui_get_focus_owner() == null
	# the focus on a control here, or nowhere in the window and held here last
	return viewport.gui_get_focus_owner() != null or (nowhere and _held_last.get(get_window().get_instance_id()) == get_instance_id())


## A control of this app took the window's focus: this is the app that held
## it last; and a field taking it has the keyboard followed from now on.
func _focused(on: Control) -> void:
	_held_last[get_window().get_instance_id()] = get_instance_id()
	if on is LineEdit or on is TextEdit:
		set_physics_process(true)


## Each physics frame while a field holds the focus, the keyboard's height
## read, and the canvas fitted again whenever it moved; the field let go, the
## keyboard is gone, the canvas fitted without it, and nothing more is read.
func _physics_process(_delta: float) -> void:
	var focus := viewport.gui_get_focus_owner()
	var typing: bool = focus is LineEdit or focus is TextEdit
	var height: float = float(reads_keyboard.call()) if typing else 0.0
	if height != _keyboard:
		_keyboard = height
		_fit()
	if not typing:
		set_physics_process(false)


## Entering the tree, the project's base read - so settings a host applied in
## its own _ready, before it added this, are the base - and the canvas fitted
## to the rect it comes in with; resized, fitted again.
func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_base = Vector2i(ProjectSettings.get_setting(WIDTH), ProjectSettings.get_setting(HEIGHT))
		viewport.size_2d_override = get_base()
		_fit()
	elif what == NOTIFICATION_RESIZED:
		_fit()


## The canvas fitted to the rect: the base turned with it; the scale, the one
## that fits the base inside the rect, or the least, and never so large the
## safe room is under the floor; the override grown past the base along the
## side with room, so one scale covers the rect; and the safe rect handed to
## the canvas. A rect of no width or no height fits nothing until it has
## both: there is no scale that fits a base into nothing.
func _fit() -> void:
	if size.x == 0.0 or size.y == 0.0:
		return
	var turning: bool = (size.y > size.x) != _turned
	_turned = size.y > size.x
	var dpi := float(reads_dpi.call())
	var window := Rect2(Vector2.ZERO, get_window().size)
	var rect := get_global_rect()
	var unobscured := Rect2(reads_safe_area.call())
	# the system's area is given on the screen: moved to be measured, as the window and this rect are, from the window's corner
	if unobscured.has_area():
		unobscured.position -= Vector2(get_window().position)
	var corner := float(reads_corner_um.call())
	var gutter := float(canvas.get_theme_constant(&"edge", REAL_SIZE))
	# the least a base pixel may be drawn, in the rect's pixels: 25,400 thousandths of a millimetre to the inch
	var least: float = canvas.get_theme_constant(&"least_pixel_um", REAL_SIZE) / 25400.0 * dpi
	var steady := SafeArea.covered(window, rect, unobscured, 0.0, corner, dpi)
	var drawn := SafeArea.drawn_at(size, steady, Vector2(get_base()), least, float(canvas.get_theme_constant(&"floor", REAL_SIZE)), gutter)
	viewport.size_2d_override = Vector2i((size / drawn).round())
	canvas.set_insets(SafeArea.insets(SafeArea.covered(window, rect, unobscured, _keyboard, corner, dpi), drawn, gutter))
	if turning:
		_measure_again.call_deferred()


## Once the turn has been laid out, everything on the canvas asked what it
## needs again, and so laid again in the safe rect by it. DEFERRED, NEVER
## AWAITED: the deferred call is dropped if this is freed before the end of
## the frame.
func _measure_again() -> void:
	# every piece standing on the canvas
	for piece: Node in canvas.get_children():
		if piece is Control:
			(piece as Control).update_minimum_size()
